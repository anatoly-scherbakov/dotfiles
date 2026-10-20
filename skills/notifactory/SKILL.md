---
name: github-notifications
description: Investigate unread GitHub notifications against local source before planning a GitHub action. Use when the user invokes /github-notifications in Plan mode.
disable-model-invocation: true
---

# GitHub Notifications

This skill turns unread GitHub notifications into evidence-grounded,
user-selected GitHub action plans. It completes the relevant read-only
investigation before offering an action. Planning makes no GitHub or repository
changes; a later confirmed execution both carries out the chosen action and
cleans up its handled notification.

## Plan-mode gate

This skill runs only in Plan mode. A skill cannot switch the app's mode itself.
When Plan mode or a structured-question tool is unavailable, stop with:

> This skill runs only in Plan mode. Switch with `/plan` or Shift+Tab, then
> invoke `/github-notifications` again.

## Inbox snapshot

1. Authentication is checked with `gh auth status`. An authentication failure
   or inaccessible repository ends the workflow without changing state.
2. The unread inbox is fetched with:

   ```sh
   gh api 'notifications?all=false&participating=false&per_page=100' --paginate
   ```

   Only entries whose `unread` value is `true` belong in the snapshot. The
   returned order is newest first.
3. The active conversation keeps each snapshot notification's thread ID and
   `updated_at` value. A deferred notification remains unread but is not shown
   again during the same snapshot unless it receives newer activity.

If the snapshot is empty, report that there are no unread notifications.

## Local source evidence

For every notification with a repository subject, local evidence is gathered
before a GitHub action is presented:

1. A candidate checkout under `~/projects/<repository>` is verified by matching
   its `origin` remote to the notification repository. A directory name alone
   is not enough. Multiple matching checkouts require a structured choice; no
   checkout is selected arbitrarily.
2. Repository-root and path-specific `AGENTS.md` or `CLAUDE.md` files are read.
   The repository's branch, `HEAD`, and `git status --short --branch` output
   are recorded. A dirty checkout remains inspectable but is never modified,
   fetched, switched, or used to create a worktree.
3. For a pull-request notification, run the read-only fetch-and-review phase of
   the `review-pr` skill before offering an action. Its review covers the pull
   request description, exact diff, comments, and checks; it reports only
   issues introduced by the pull request and respects its stated scope. Do not
   enter its later fix-selection or implementation phase.
4. Trace the notification's substantive claim into authoritative local source
   and relevant tests or manifests. For `w3c/json-ld-api`, this includes
   `index.html` and the applicable test manifest or input. Findings cite the
   exact local file and line.
5. Local findings are labelled with the recorded revision. They are evidence,
   not proof that the remote issue or pull request still has the same state.

When no verified checkout is available, state that local validation was
unavailable and limit the analysis to the GitHub notification and its linked
material.

## Per-notification workflow

For the first unprocessed notification:

1. Fetch `notifications/threads/<id>`. The presentation starts with a
   prominent heading in the form
   `## Issue · [owner/repo#123](https://github.com/owner/repo/issues/123)` or
   `## Pull request · [owner/repo#123](https://github.com/owner/repo/pull/123)`,
   before the title and analysis. The link is constructed only after validating
   that `subject.url` has the expected `repos/<owner>/<repo>/(issues|pulls)/<number>`
   shape and matches the notification's repository; its raw API URL is never
   used as the browser link. A subject without a valid issue or pull-request
   number has only its type and repository; no identifier is invented. The
   report also includes the reason and update time.
2. Inspect the exact triggering material when it is available. The
   `subject.latest_comment_url` takes priority; `subject.url` supplies the
   issue or pull-request context. A current issue or pull-request view may
   provide state and related discussion, but it does not replace the exact
   event. If GitHub exposes only a subscription reason, state that limitation.
3. Complete the local source investigation and, for a pull request, the
   `review-pr` review described above before summarizing the notification or
   offering an action. The summary includes the review result, relevant local
   source/test citations, pull-request checks, and any revision or checkout
   limitation. An investigation is never an action offered to the user.
4. Use a structured question to select one GitHub-facing disposition. For a
   pull request, the relevant dispositions are a review event: approval,
   comment, or requested changes; marking the notification read with no other
   GitHub contribution; a reaction; or deferral. For another notification, the
   relevant dispositions may also include an unposted reply or an
   implementation that will later lead to a pull request. Deferral is the only
   disposition that intentionally leaves a notification unread.
5. Produce the selected action plan, then advance to the next unprocessed
   notification. A reply is an unposted draft in a raw Markdown code block. A
   review plan identifies the exact pull request, its intended event, and any
   unposted review body. An implementation plan identifies the affected
   repository and stops before creating a worktree, editing files, or creating
   a pull request. Every non-deferred plan names its source notification thread
   ID and reserves the read-marking transaction below for a separate
   post-Plan-mode request. A reaction plan identifies the exact opening post
   or specific comment, its GitHub URL and target kind, a supported GitHub
   reaction `content` value with
   its displayed emoji, and verification that the authenticated user's reaction
   on that same target has the selected content. Later execution requires
   approval for that exact target and reaction; `200` means it was already
   present and `201` means it was created.

## Execution handoff

After the user explicitly asks to execute a prepared plan outside Plan mode:

1. For each non-deferred plan, re-fetch its notification thread and compare its
   `updated_at`, subject URL, and `latest_comment_url` with the planning
   snapshot. If an intervening event changed any of them, leave the thread
   unread and report it for normal triage.
2. Carry out the approved GitHub contribution, if any. A failed, uncertain, or
   unposted contribution leaves its source notification unread. A `200`
   reaction result counts as the approved state already being present.
3. After a successful contribution, or for an explicit read-and-skip plan,
   mark that same source thread read with
   `PATCH /notifications/threads/<thread_id>`, then re-fetch it to confirm
   `unread: false`.
4. Refresh the unread inbox after every planned thread has been handled. If the
   authenticated user's completed action surfaced a new notification, mark it
   read only when the exact target and triggering artifact can be matched to
   that recorded action and no later activity is present. Ambiguous or deferred
   notifications remain unread and are reported.

## Constraints

- No `POST`, `PATCH`, unsubscribe, mute, reaction, comment, review, issue or
  pull-request state change, repository edit, worktree creation, commit, or
  pull request is performed while this skill runs in Plan mode.
- A plan may recommend a later GitHub action. Execution needs a separate user
  request after leaving Plan mode and follows the execution handoff, including
  notification cleanup.
- At the end of the initial snapshot, distinguish a truly empty inbox from a
  fully planned snapshot, whose notifications remain unread until execution.
  New or updated notifications may be offered as another snapshot; no silent
  restart occurs.
