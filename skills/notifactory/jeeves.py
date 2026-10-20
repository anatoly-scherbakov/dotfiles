"""Notifactory commands: fetch notification batches and act on threads."""

import json
import re
import tempfile
import time
import webbrowser
from enum import Enum
from pathlib import Path
from typing import Annotated, Optional

import sh
from typer import Argument, Option

DEFAULT_SKIP_FILE = Path(tempfile.gettempdir()) / 'notifactory-skipped.json'
FAILED_CONCLUSIONS = {
    'FAILURE', 'TIMED_OUT', 'CANCELLED', 'ACTION_REQUIRED', 'ERROR',
}
MERGE_METHOD_PREFERENCE = ('squash', 'merge', 'rebase')
CHECK_SUITE_BRANCH = re.compile(r' for (?P<branch>\S+) branch$')
PULL_REQUEST_URL = re.compile(
    r'github\.com/(?P<owner>[^/]+)/(?P<name>[^/]+)/pull/(?P<number>\d+)',
)
# GitHub re-subscribes an approval's author a second or two after the approval.
RESUBSCRIPTION_DELAY_SECONDS = 10

SkipFileOption = Annotated[
    Path,
    Option(help='JSON map of skipped thread ID to its updated_at.'),
]


class Action(str, Enum):
    """What to do with a notification thread."""

    done = 'done'
    skip = 'skip'
    unsubscribe = 'unsubscribe'
    approve = 'approve'
    approve_unsubscribe = 'approve-unsubscribe'
    merge = 'merge'
    open = 'open'


class MergeMethod(str, Enum):
    """Pull request merge method."""

    squash = 'squash'
    merge = 'merge'
    rebase = 'rebase'


def _gh(*arguments: str) -> str:
    return str(sh.gh(*arguments, _tty_out=False))


def _gh_json(*arguments: str):
    return json.loads(_gh(*arguments))


def _read_skipped(skip_file: Path) -> dict[str, str]:
    if not skip_file.exists():
        return {}

    return json.loads(skip_file.read_text())


def _first_lines(text: Optional[str], count: int = 5) -> str:
    return '\n'.join((text or '').strip().splitlines()[:count])


def _latest_comment(subject: dict) -> Optional[dict]:
    comment_url = subject.get('latest_comment_url')
    if not comment_url or comment_url == subject.get('url'):
        return None

    comment = _gh_json('api', comment_url)
    return {
        'author': comment['user']['login'],
        'body': _first_lines(comment.get('body')),
    }


def _pull_request(url: str, viewer: str) -> dict:
    pull_request = _gh_json(
        'pr', 'view', url, '--json',
        'url,author,state,isDraft,reviewDecision,reviews,mergeable,'
        'mergeStateStatus,statusCheckRollup',
    )
    my_reviews = [
        review['state']
        for review in pull_request['reviews']
        if review['author']['login'] == viewer
    ]
    failed_checks = [
        check.get('name') or check.get('context')
        for check in pull_request['statusCheckRollup']
        if (check.get('conclusion') or check.get('state')) in FAILED_CONCLUSIONS
    ]
    return {
        'url': pull_request['url'],
        'author': pull_request['author']['login'],
        'is_mine': pull_request['author']['login'] == viewer,
        'state': pull_request['state'],
        'is_draft': pull_request['isDraft'],
        'review_decision': pull_request['reviewDecision'] or None,
        'my_review': my_reviews[-1] if my_reviews else None,
        'mergeable': pull_request['mergeable'],
        'merge_state_status': pull_request['mergeStateStatus'],
        'failed_checks': failed_checks,
    }


def _check_suite_run(notification: dict) -> Optional[str]:
    match = CHECK_SUITE_BRANCH.search(notification['subject']['title'])
    if match is None:
        return None

    runs = _gh_json(
        'run', 'list',
        '-R', notification['repository']['full_name'],
        '--branch', match.group('branch'),
        '--status', 'failure',
        '--limit', '1',
        '--json', 'url',
    )
    return runs[0]['url'] if runs else None


def _describe(notification: dict, viewer: str) -> dict:
    subject = notification['subject']
    described = {
        'thread_id': notification['id'],
        'type': subject['type'],
        'title': subject['title'],
        'repository': notification['repository']['full_name'],
        'reason': notification['reason'],
        'updated_at': notification['updated_at'],
        'url': notification['repository']['html_url'],
        'latest_comment': _latest_comment(subject),
    }

    if subject['type'] == 'PullRequest':
        described.update(_pull_request(_browser_url(subject), viewer))
    elif subject['type'] == 'CheckSuite':
        described['url'] = _check_suite_run(notification) or described['url']
    elif subject.get('url'):
        target = _gh_json('api', subject['url'])
        described['url'] = target.get('html_url') or described['url']
        described['state'] = target.get('state')

    return described


def _browser_url(subject: dict) -> str:
    return _gh_json('api', subject['url'])['html_url']


def _thread(thread_id: str) -> dict:
    return _gh_json('api', f'notifications/threads/{thread_id}')


def _mark_done(thread_id: str) -> None:
    _gh('api', '-X', 'DELETE', f'notifications/threads/{thread_id}')


def _unsubscribe(thread_id: str) -> None:
    _gh(
        'api', '-X', 'DELETE',
        f'notifications/threads/{thread_id}/subscription',
    )


def _viewer_subscription(url: str) -> str:
    match = PULL_REQUEST_URL.search(url)
    if match is None:
        raise ValueError(f'Not a pull request URL: {url}')

    return _gh(
        'api', 'graphql',
        '-f', 'query=query($owner: String!, $name: String!, $number: Int!) {'
        ' repository(owner: $owner, name: $name) {'
        ' pullRequest(number: $number) { viewerSubscription } } }',
        '-f', f'owner={match.group("owner")}',
        '-f', f'name={match.group("name")}',
        '-F', f'number={match.group("number")}',
        '--jq', '.data.repository.pullRequest.viewerSubscription',
    ).strip()


def _merge_method(url: str) -> MergeMethod:
    repository = _gh_json(
        'repo', 'view', url.split('/pull/')[0], '--json',
        'squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed',
    )
    allowed = {
        'squash': repository['squashMergeAllowed'],
        'merge': repository['mergeCommitAllowed'],
        'rebase': repository['rebaseMergeAllowed'],
    }
    return MergeMethod(next(
        method for method in MERGE_METHOD_PREFERENCE if allowed[method]
    ))


def batch(
    size: Annotated[int, Option(help='Notifications per batch.')] = 4,
    skip_file: SkipFileOption = DEFAULT_SKIP_FILE,
):
    """Print the next batch of unread notifications as JSON, newest first."""
    viewer = _gh('api', 'user', '--jq', '.login').strip()
    pages = _gh_json(
        'api', 'notifications?all=false&per_page=100', '--paginate', '--slurp',
    )
    skipped = _read_skipped(skip_file)
    pending = sorted(
        (
            notification
            for page in pages
            for notification in page
            if skipped.get(notification['id']) != notification['updated_at']
        ),
        key=lambda notification: notification['updated_at'],
        reverse=True,
    )
    print(json.dumps(
        {
            'remaining': len(pending),
            'batch': [
                _describe(notification, viewer)
                for notification in pending[:size]
            ],
        },
        indent=2,
    ))


def act(
    thread_id: Annotated[str, Argument(help='Notification thread ID.')],
    action: Annotated[Action, Argument(help='What to do with the thread.')],
    method: Annotated[
        Optional[MergeMethod],
        Option(help='Merge method; defaults to the first one the repository allows of squash, merge, rebase.'),
    ] = None,
    skip_file: SkipFileOption = DEFAULT_SKIP_FILE,
):
    """Carry out one action on a notification thread and print the result."""
    thread = _thread(thread_id)
    subject = thread['subject']
    url = (
        _browser_url(subject) if subject.get('url')
        else thread['repository']['html_url']
    )

    if action in {Action.skip, Action.open}:
        skipped = _read_skipped(skip_file)
        skipped[thread_id] = thread['updated_at']
        skip_file.write_text(json.dumps(skipped, indent=2))

    if action == Action.skip:
        print(f'{url} skipped')
        return

    if action == Action.open:
        webbrowser.open(url)
        print(f'{url} opened, skipped')
        return

    if action in {Action.approve, Action.approve_unsubscribe}:
        _gh('pr', 'review', url, '--approve')

    if action == Action.approve_unsubscribe:
        time.sleep(RESUBSCRIPTION_DELAY_SECONDS)

    if action == Action.merge:
        chosen = method or _merge_method(url)
        _gh('pr', 'merge', url, f'--{chosen.value}')

    if action in {Action.unsubscribe, Action.approve_unsubscribe}:
        _unsubscribe(thread_id)

    _mark_done(thread_id)
    if action == Action.done:
        print(f'{url} done')
    elif action == Action.approve_unsubscribe:
        print(f'{url} {action.value}, done, {_viewer_subscription(url)}')
    else:
        print(f'{url} {action.value}, done')
