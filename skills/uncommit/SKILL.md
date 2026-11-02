---
name: uncommit
description: Cancel commits contributed by the current open pull request while keeping its changes unstaged. Use to rebuild a noisy PR history, including one layer of a stacked PR.
---

# Uncommit

Reset the current branch to its open pull request's latest base branch, keeping
its changes as an **unstaged** diff. Parent PR commits remain in history. A
follow-up `/commit` can recreate one-file-per-commit history.

## Invoke

Run the accompanying script without arguments:

```bash
bash <skill-dir>/uncommit.sh
```

## Behavior

1. Refuse on detached `HEAD`, the repository's default branch, or a dirty working tree.
2. Use `gh pr view` to find the current branch's **open** PR and its `baseRefName`.
   Refuse if no matching open PR exists; never fall back to the default branch.
3. Verify that `origin` matches the PR repository, then fetch the PR's base branch.
4. Rebase onto `origin/<PR-base>`. On conflict, abort the rebase and exit with code `3`.
5. Mixed-reset to `origin/<PR-base>`, preserving the working tree and leaving
   PR changes unstaged. If the branch has no commits ahead of its base, do nothing.

For example, a draft PR targeting `yaml-ld-tests` resets to
`origin/yaml-ld-tests`, preserving that parent branch's commits. A PR targeting
`master` resets to `origin/master`.

## Rules

- **Never lose changes.** Use the script's mixed reset and abort-on-conflict
  rebase. Never substitute `--hard`.
- **Never push.** The user decides when to publish the rebuilt history; a later
  push normally requires force-with-lease.
- Exit code `2` means the script refused. Exit code `3` means a rebase conflict.
  Surface stderr and stop; do not work around either result.
- For a dirty tree, tell the user to commit, stash, or discard changes before retrying.
- If the user explicitly requests another base, do not use this script. Explain
  the target, then use `git reset --soft <ref>` as requested. This leaves changes staged.
