---
name: uncommit
description: Cancel all commits on the current branch while keeping the changes in the working tree. Use when a PR has accumulated too many small commits and you want to squash the history flat so it can be recommitted from scratch.
---

# Uncommit

Squashes every commit on the current branch into a single **unstaged** diff on top of the latest default branch, keeping every change in the working tree. The resulting state looks as if the user had made all the changes locally but never staged or committed them — so a follow-up `/commit` can stage and commit them one file at a time.

Use this when a branch has too many noisy back-and-forth commits and the user wants to start the commit history over (typically followed by `/commit` to recreate clean, one-file-per-commit history).

## How to invoke

Just run the accompanying script — it does the whole thing deterministically:

```bash
bash "$(dirname "$0")/uncommit.sh"
```

…or, from the agent, call `bash <skill-dir>/uncommit.sh`. The script takes no arguments.

## What the script does

1. Refuses to run on the default branch (`master`/`main`) or on detached `HEAD`.
2. Refuses to run on a dirty working tree (so the staged result is unambiguously "branch's net commits").
3. Asks `gh repo view --json defaultBranchRef` for the repo's default branch (authoritative — no guessing from `origin/HEAD`, which is often stale).
4. `git fetch origin <default>`.
5. **Rebases** the current branch onto `origin/<default>` first. This is essential: it makes the merge-base equal to `origin/<default>`, so the reset diff is exactly what the branch contributes and contains **no spurious reverts** of changes the default branch made after the branch point. On rebase conflicts, aborts and exits non-zero so the user can resolve manually.
6. `git reset origin/<default>` (mixed — the default) — branch commits become **unstaged** changes; working tree untouched. Mixed rather than `--soft` so that `/commit` can stage each file individually afterwards instead of being forced to squash everything back into one commit.
7. Prints a one-line report.

## Rules (for the agent)

- **Never lose changes.** The script only ever uses `git reset` (mixed — keeps the working tree) and `git rebase` (which it aborts on conflict). Never substitute `--hard`.
- **Never push.** Especially not `--force`. The user will push themselves once they're happy with the new history. They will need to force-push afterwards because the branch has been rebased.
- If the script exits with code `2` (refused) or `3` (rebase conflicts), surface its stderr to the user and stop. Do not try to "work around" the refusal — the conditions exist for a reason.
- If the user explicitly requests a non-default base (e.g. "uncommit back to `origin/release-1.2`"), don't use this skill — just do `git reset --soft <ref>` directly after warning them.

## Examples

- Branch `171-remove-spec-folder` with 12 commits on top of `origin/master`, clean tree:
  → `bash uncommit.sh` → rebases onto latest `origin/master`, mixed-resets, reports "squashed 12 commit(s)". Changes show up as unstaged modifications.

- Branch `master` or `main`:
  → Script refuses with exit code 2. Tell the user to switch branches.

- Dirty working tree:
  → Script refuses with exit code 2. Tell the user to commit, stash, or discard their working changes first.

- Rebase hits conflicts:
  → Script aborts the rebase and exits with code 3. Surface the conflict message; the user must rebase manually before retrying.
