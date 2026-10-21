---
name: notifactory
description: Cycle through unread GitHub notifications, ask the user what to do with each, and do it. Use when the user invokes /notifactory.
disable-model-invocation: true
---

# Notifactory

Triage the unread GitHub inbox: show each notification, ask what to do, do it.
Do not analyze diffs, read local checkouts, or investigate claims; the user
decides from the summary alone and asks for more when they want it.

## Commands

`jeeves.py` in this skill's base directory does the GitHub work. Run it with
[jeeves-shell](https://pypi.org/project/jeeves-shell/), pointing
`JEEVES_ROOT` at that directory:

```sh
JEEVES_ROOT=<skill base directory> uvx --from jeeves-shell --with sh j <command>
```

- `j batch --skip-file <file>` prints the next four unread notifications,
  newest first, as JSON, with the count remaining. Each has its thread ID,
  verbatim title, browser URL, type, reason, `updated_at`, and latest comment;
  a pull request adds author, `is_mine`, state, draft flag, review decision,
  the user's own latest review, mergeability, and failed checks.
- `j act <thread-id> <action> --skip-file <file>` carries out one action and
  prints its result line. Actions: `done`, `skip`, `unsubscribe`, `approve`,
  `approve-unsubscribe`, `merge` (optional `--method`), `open`.

Keep the skip file in the session's scratchpad directory, so a skipped thread
returns in a later session or once it has newer activity.

## Present

For each notification in the batch, print a heading
`## <type> · <url>`, then the verbatim title, the reason, and `updated_at`;
for a pull request, its author, whether it is open, merged, or closed, the
review decision, and whether the user has approved it; then the latest
comment's author and gist, if any.

## Ask

Ask about the whole batch in one structured question call, one question per
notification. The question text carries the verbatim title, the URL, and, for
a pull request, merge state and the user's approval. Pick up to four options:

- **Merge** (open pull request the user's own guidance marks as mergeable
  from triage; list it first). Offer it only when `merge_state_status`
  allows a merge (`CLEAN`, `UNSTABLE` or `HAS_HOOKS`); never when it is
  `BLOCKED`, `DIRTY`, `BEHIND`, `DRAFT` or `UNKNOWN`. When `failed_checks` is
  non-empty, name them and confirm before merging.
- **Approve & unsubscribe** (open pull request by someone else that the user
  has not approved; list it first unless Merge applies). Where the user's own
  guidance keeps subscriptions on approval, offer **Approve** instead.
- **Done**: clear it from the inbox.
- **Unsubscribe**: unsubscribe from the thread, then clear it. A later
  mention, or the user's own comment or review, subscribes them again.
- **Skip**: leave it unread.
- **Open**: open it in the browser and leave it unread, skipped for this run.

The free-text answer covers anything else (a comment, a reaction, close,
"tell me more"). Carry it out with `gh` as instructed, drafting any text the
user did not dictate and showing it before posting; then clear the thread
with `j act <thread-id> done`.

## Act

Run `j act` for every answer in the batch, relay each result line, then run
`j batch` again; it re-reads the inbox, so it also picks up anything that
arrived meanwhile. An empty batch ends the run: say whether the inbox is
clear or holds only skipped threads.
