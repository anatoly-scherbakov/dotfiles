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
# An asynchronous merge usually settles within seconds; stop polling after 30.
MERGE_POLL_INTERVAL_SECONDS = 3
MERGE_POLL_ATTEMPTS = 10
# Bounds the `gh pr list` calls that follow a branch chain in each direction.
STACK_CHAIN_LIMIT = 10
STACK_QUERY = (
    'query($owner: String!, $name: String!, $number: Int!) {'
    ' repository(owner: $owner, name: $name) { pullRequest(number: $number) {'
    ' stack { baseRefName entries(first: 100) {'
    ' nodes { position pullRequest { url state } } } } } } }'
)

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


def _default_branch(url: str) -> str:
    return _gh(
        'repo', 'view', url.split('/pull/')[0],
        '--json', 'defaultBranchRef', '--jq', '.defaultBranchRef.name',
    ).strip()


def _native_stack(url: str) -> Optional[dict]:
    """Return the GitHub stack holding the pull request, or None."""
    match = PULL_REQUEST_URL.search(url)
    if match is None:
        raise ValueError(f'Not a pull request URL: {url}')

    return _gh_json(
        'api', 'graphql',
        '-f', f'query={STACK_QUERY}',
        '-f', f'owner={match.group("owner")}',
        '-f', f'name={match.group("name")}',
        '-F', f'number={match.group("number")}',
    )['data']['repository']['pullRequest']['stack']


def _open_pull_requests(url: str, *arguments: str) -> list[dict]:
    return _gh_json(
        'pr', 'list', '-R', url.split('/pull/')[0], '--state', 'open',
        '--json', 'url,baseRefName,headRefName', *arguments,
    )


def _branch_chain(
    url: str, base: str, head: str, default_branch: str,
) -> list[str]:
    """List the open pull requests chained by branches, bottom first."""
    below = []
    while base != default_branch and len(below) < STACK_CHAIN_LIMIT:
        parents = _open_pull_requests(url, '--head', base)
        if not parents:
            break
        below.insert(0, parents[0]['url'])
        base = parents[0]['baseRefName']

    above = []
    while len(above) < STACK_CHAIN_LIMIT:
        children = _open_pull_requests(url, '--base', head)
        if not children:
            break
        above.append(children[0]['url'])
        head = children[0]['headRefName']

    return [*below, url, *above]


def _stack(url: str, base: str, head: str, default_branch: str) -> dict:
    """Place the pull request in its stack of open pull requests."""
    native = _native_stack(url) or {'entries': {'nodes': []}}
    chain = [
        entry['pullRequest']['url']
        for entry in sorted(
            native['entries']['nodes'], key=lambda entry: entry['position'],
        )
        if entry['pullRequest']['state'] == 'OPEN'
    ]
    # Once the rest of a GitHub stack has merged, its last open pull request
    # may still head a chain of branches.
    is_native = len(chain) >= 2
    if not is_native:
        chain = _branch_chain(url, base, head, default_branch)
    elif chain[-1] == url:
        # A pull request based on the top's branch sits above the stack.
        chain = [*chain[:-1], *_branch_chain(url, base, head, base)]

    if len(chain) < 2:
        position = 'none'
    elif chain[0] == url:
        position = 'bottom'
    elif chain[-1] == url:
        position = 'top'
    else:
        position = 'middle'

    return {
        'stack_position': position,
        'stack_size': len(chain),
        # Only a GitHub stack merges its lower pull requests along with the top.
        'stack_native': is_native,
        'stack': chain,
        'stack_base_branch': native['baseRefName'] if is_native else None,
    }


def _pull_request(url: str, viewer: str) -> dict:
    pull_request = _gh_json(
        'pr', 'view', url, '--json',
        'url,author,state,isDraft,reviewDecision,reviews,mergeable,'
        'mergeStateStatus,statusCheckRollup,baseRefName,headRefName',
    )
    default_branch = _default_branch(url)
    # Only an open pull request has a stack worth tracing.
    stack = _stack(
        url, pull_request['baseRefName'], pull_request['headRefName'],
        default_branch,
    ) if pull_request['state'] == 'OPEN' else {
        'stack_position': 'none', 'stack_size': 0,
        'stack_native': False, 'stack': [],
    }
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
        'base_branch': pull_request['baseRefName'],
        # A pull request stacked on another branch merges only into that branch.
        'targets_default_branch': pull_request['baseRefName'] == default_branch,
        'review_decision': pull_request['reviewDecision'] or None,
        'my_review': my_reviews[-1] if my_reviews else None,
        'mergeable': pull_request['mergeable'],
        'merge_state_status': pull_request['mergeStateStatus'],
        'failed_checks': failed_checks,
        'stack_position': stack['stack_position'],
        'stack_size': stack['stack_size'],
        'stack_native': stack['stack_native'],
        'stack': stack['stack'],
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


def _merge_async(url: str, method: MergeMethod) -> dict:
    """Request an asynchronous merge and poll until it leaves `pending`."""
    match = PULL_REQUEST_URL.search(url)
    if match is None:
        raise ValueError(f'Not a pull request URL: {url}')

    endpoint = (
        f'repos/{match.group("owner")}/{match.group("name")}'
        f'/pulls/{match.group("number")}/merge-async'
    )
    try:
        result = _gh_json(
            'api', '-X', 'PUT', endpoint, '-f', f'merge_method={method.value}',
        )
        uuid = (result.get('details') or {}).get('uuid')
        for _ in range(MERGE_POLL_ATTEMPTS):
            if result['status'] != 'pending':
                break
            time.sleep(MERGE_POLL_INTERVAL_SECONDS)
            result = _gh_json('api', f'{endpoint}/{uuid}')
    except sh.ErrorReturnCode as error:
        return {'status': 'failed', 'details': {'message': _gh_error(error)}}

    return result


def _gh_error(error: sh.ErrorReturnCode) -> str:
    try:
        return json.loads(error.stdout)['message']
    except (ValueError, KeyError, TypeError):
        return error.stderr.decode().strip()


def _merge_outcome(url: str, result: dict, state: str) -> Optional[str]:
    """Describe a merge that did not happen; None once the PR is merged."""
    # The async result is authoritative; `gh pr view` can lag behind it.
    if state == 'MERGED' or result['status'] == 'merged':
        return None

    if result['status'] == 'enqueued':
        return f'{url} enqueued, not done'

    if result['status'] == 'pending':
        return f'{url} merge pending, not done'

    message = (result.get('details') or {}).get('message') or result['status']
    return f'{url} not merged: {message}'


def _merge_refusal(url: str) -> Optional[str]:
    """Explain why the pull request must not merge; None when it may."""
    branches = _gh_json('pr', 'view', url, '--json', 'baseRefName,headRefName')
    default_branch = _default_branch(url)
    stack = _stack(
        url, branches['baseRefName'], branches['headRefName'], default_branch,
    )
    position = stack['stack_position']

    if position in {'bottom', 'middle'}:
        return (
            f'{url} not merged: it is below {stack["stack"][-1]} in a stack;'
            ' merge the stack from the top'
        )

    if position == 'top' and not stack['stack_native']:
        return (
            f'{url} not merged: its stack is chained by branches, not a GitHub'
            f' stack, so a merge would land only in {branches["baseRefName"]}'
        )

    if position == 'top' and stack['stack_base_branch'] != default_branch:
        return (
            f'{url} not merged: its stack targets'
            f' {stack["stack_base_branch"]}, not the default branch'
        )

    if position == 'none' and branches['baseRefName'] != default_branch:
        return (
            f'{url} not merged: it targets {branches["baseRefName"]},'
            ' not the default branch'
        )

    return None


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
        refusal = _merge_refusal(url)
        if refusal is not None:
            print(refusal)
            return

        # For the top of a stack, this merges every open pull request below it.
        result = _merge_async(url, method or _merge_method(url))
        state = _gh(
            'pr', 'view', url, '--json', 'state', '--jq', '.state',
        ).strip()
        outcome = _merge_outcome(url, result, state)
        if outcome is not None:
            print(outcome)
            return

    if action in {Action.unsubscribe, Action.approve_unsubscribe}:
        _unsubscribe(thread_id)

    _mark_done(thread_id)
    if action == Action.done:
        print(f'{url} done')
    elif action == Action.approve_unsubscribe:
        print(f'{url} {action.value}, done, {_viewer_subscription(url)}')
    elif action == Action.merge:
        print(f'{url} merged, done')
    else:
        print(f'{url} {action.value}, done')
