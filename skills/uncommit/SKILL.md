---
name: uncommit
description: Cancel all commits on the current branch while keeping the changes in the working tree. Use when a PR has accumulated too many small commits and you want to squash the history flat so it can be recommitted from scratch.
---

# Uncommit

Resets the current branch back to its base, discarding commit history but **keeping every change** in the working tree. The resulting state looks as if the user had made all the changes locally but never committed them.

Use this when a branch has too many noisy back-and-forth commits and the user wants to start the commit history over (typically followed by `/commit` to recreate clean, one-file-per-commit history).

## Rules

- **Never lose changes.** Always use `git reset --soft` (or `--mixed`), never `--hard`. The working tree and the union of all uncommitted diffs must be preserved.
- **Refuse on the default branch.** If the current branch is `master` or `main`, stop and ask the user — uncommitting on the default branch is almost never what they want.
- **Refuse with a dirty working tree unless the user confirms.** If `git status` shows uncommitted changes before the reset, surface them and ask before proceeding: the reset will mix them together with the previously-committed changes.
- **Do not push.** Never run `git push` (especially not `--force`). The user will push themselves once they are happy with the new history.

## Workflow

1. **Identify the current branch:**
   `git branch --show-current`. If it is `master` or `main`, stop and ask the user what they actually want.

2. **Identify the base commit to reset to.** In order of preference:
   - The upstream tracking branch, if set: `git rev-parse --abbrev-ref --symbolic-full-name @{u}`.
   - Otherwise the merge-base with the default branch: `git merge-base HEAD origin/master` (or `origin/main`, whichever exists).
   - If neither resolves, ask the user for the base ref.

3. **Check for a dirty tree:**
   `git status --porcelain`. If non-empty, show the output to the user and confirm before continuing.

4. **Count what will be uncommitted** (for the report):
   `git rev-list --count <base>..HEAD`. If the count is `0`, stop — there is nothing to uncommit.

5. **Reset:**
   `git reset --soft <base>`. This moves `HEAD` back to `<base>` while leaving the index and working tree untouched, so every change from the uncommitted commits shows up as staged.

6. **Report:**
   Print one short line: how many commits were uncommitted, the base they were reset to, and a reminder that the changes are now staged (run `git status` to see them, or `/commit` to recreate history).

## Examples

- Branch `171-remove-spec-folder` with 12 commits on top of `origin/master`:
  → `git reset --soft origin/master` → "Uncommitted 12 commits back to `origin/master`. All changes are staged; run `/commit` to recreate history."

- Branch `master`:
  → Refuse. Ask the user to confirm or switch branches first.

- Branch with a tracking upstream `origin/feature-x` that is 3 commits behind HEAD:
  → `git reset --soft origin/feature-x` → "Uncommitted 3 commits back to `origin/feature-x`."
