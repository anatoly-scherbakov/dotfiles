---
name: notifactory
description: Cycle through unread GitHub notifications, ask the user what to do with each, and do it. Use when the user invokes /notifactory.
disable-model-invocation: true
---

# Notifactory

Triage the unread GitHub inbox: show each notification, ask what to do, do it.
Do not analyze diffs, read local checkouts, or investigate claims; the user
decides from the summary alone and asks for more when they want it.

## Fetch

```sh
gh api 'notifications?all=false&per_page=100' --paginate
```

If the list is empty, say the inbox is clear and stop.

## Present

Take notifications in batches of up to four, newest first. For each, print:

- a heading `## <Issue|Pull request|...> · <full browser URL>`, the URL built
  from `subject.url` (`repos/<owner>/<repo>/pulls/<n>` →
  `https://github.com/<owner>/<repo>/pull/<n>`; `issues/<n>` likewise). When
  `subject.url` is null or has another shape (check suites, releases,
  discussions), use `subject.type` and `repository.html_url`;
- the subject title, `reason`, and `updated_at`;
- when `subject.latest_comment_url` is set, its author and the first few
  lines of its body, so the user sees what triggered the notification.

## Ask

Ask about the whole batch in one structured question call, one question per
notification. Pick up to four options per notification from:

- **Done**: `gh api -X DELETE notifications/threads/<id>` (clears it from the
  inbox).
- **Skip**: leave it unread.
- **Unsubscribe**: `gh api -X DELETE notifications/threads/<id>/subscription`,
  then mark it done.
- **Approve** (pull request with `reason: review_requested`):
  `gh pr review <url> --approve`, then mark it done.
- **Open**: `xdg-open <url>`, then leave it unread.

The free-text answer covers anything else (a comment, a reaction, merge,
close, "tell me more"). Carry it out as instructed; draft any text the user
did not dictate and show it before posting.

## Act

Execute every answer in the batch right away, report each result in one
line, then move to the next batch. At the end, re-fetch the inbox and offer
any notifications that arrived meanwhile.
