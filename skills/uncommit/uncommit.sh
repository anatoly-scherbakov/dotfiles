#!/usr/bin/env bash
# uncommit.sh — squash all commits on the current branch into a single
# unstaged diff on top of the latest default branch.
#
# Steps:
#   1. Refuse on detached HEAD or on the default branch itself.
#   2. Refuse on a dirty working tree.
#   3. Ask `gh` for the repo's default branch (authoritative — no guessing).
#   4. Fetch the default branch from origin.
#   5. Rebase the current branch onto origin/<default> so the reset diff is
#      exactly the branch's net contribution. On conflict, abort the rebase
#      and exit non-zero so the caller can resolve manually.
#   6. `git reset origin/<default>` (mixed) — branch's commits become
#      unstaged changes in the working tree, so a follow-up `/commit` can
#      stage and commit them one file at a time.
#
# Exit codes:
#   0  success (or nothing to uncommit)
#   2  refused (bad branch, dirty tree, gh missing, etc.)
#   3  rebase conflicts — user must resolve manually

set -euo pipefail

git rev-parse --git-dir >/dev/null

current=$(git branch --show-current)
if [ -z "$current" ]; then
  echo "uncommit: detached HEAD — refusing." >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "uncommit: gh CLI not found — required to detect the default branch." >&2
  exit 2
fi

default=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null || true)
if [ -z "$default" ]; then
  echo "uncommit: could not determine default branch via 'gh repo view'." >&2
  exit 2
fi

if [ "$current" = "$default" ]; then
  echo "uncommit: refusing to uncommit on the default branch ($current)." >&2
  exit 2
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "uncommit: working tree is dirty — refusing." >&2
  git status --short >&2
  exit 2
fi

git fetch --quiet origin "$default"

base="origin/$default"

if [ "$(git rev-list --count "$base..HEAD")" = "0" ]; then
  echo "uncommit: nothing to do — '$current' has no commits ahead of $base."
  exit 0
fi

if ! git rebase "$base"; then
  git rebase --abort 2>/dev/null || true
  echo >&2
  echo "uncommit: rebase onto $base produced conflicts. Resolve manually, then re-run." >&2
  exit 3
fi

count=$(git rev-list --count "$base..HEAD")
if [ "$count" = "0" ]; then
  echo "uncommit: nothing to do after rebase — all commits on '$current' were already in $base."
  exit 0
fi

git reset "$base"

echo "uncommit: squashed $count commit(s) from '$current' onto $base. All changes are unstaged."
echo "         Run 'git status' to see them, or '/commit' to recreate history file-by-file."
