---
name: wg-github
description: Review current JSON-LD Working Group pull requests and propose review or follow-up actions. Use when the user invokes /wg-github or asks about the group's GitHub review queue.
disable-model-invocation: true
---

# WG GitHub

Run the live report:

```bash
wg-github
```

It covers `w3c/yaml-ld` and non-fork repositories in `w3c` and `json-ld` whose names begin with `json-ld`. It includes non-draft PRs with no approvals, plus PRs whose current decision is `CHANGES_REQUESTED` even if they have an approval. The report distinguishes unresolved requested changes from a stale decision whose review threads are all resolved or outdated.

After reading the report, propose the next actions:

- For the user's PRs with changes requested, summarize the requested work and offer to address it.
- For the user's PRs awaiting re-review, explain that the previous change request is stale and recommend asking the reviewer who requested changes for a fresh review.
- For the user's PRs awaiting approval, recommend a specific reviewer or an appropriate review request.
- For other PRs, recommend at most three substantive, human-authored review candidates. Deprioritize dependency updates unless they affect the working group's deliverables.

Do not post comments, request reviews, change PRs, or resolve review threads unless the user explicitly asks.
