#!/usr/bin/env bash
# Keep the current PR's changes as an unstaged diff against its latest base.
# Exit 2 for refused operations; exit 3 after aborting a conflicting rebase.
set -euo pipefail

git rev-parse --git-dir >/dev/null
current=$(git branch --show-current)
if [ -z "$current" ]; then
  echo "uncommit: detached HEAD — refusing." >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "uncommit: gh CLI not found — required to detect the PR base." >&2
  exit 2
fi

repository=$(gh repo view --json defaultBranchRef,nameWithOwner \
  --jq '[.defaultBranchRef.name, .nameWithOwner] | @tsv' 2>/dev/null || true)
if [ -z "$repository" ]; then
  echo "uncommit: could not determine default branch via 'gh repo view'." >&2
  exit 2
fi
IFS=$'\t' read -r default repository_name <<< "$repository"
if [ -z "$default" ] || [ -z "$repository_name" ]; then
  echo "uncommit: invalid repository metadata — refusing." >&2
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

pull_request=$(gh pr view "$current" --json headRefName,baseRefName,state \
  --jq 'select(.state == "OPEN") | [.headRefName, .baseRefName] | @tsv' 2>/dev/null || true)
if [ -z "$pull_request" ]; then
  echo "uncommit: could not find an open PR for '$current' — refusing." >&2
  exit 2
fi
IFS=$'\t' read -r pull_request_head base_branch <<< "$pull_request"
if [ "$pull_request_head" != "$current" ] || [ -z "$base_branch" ] || [ "$base_branch" = "$current" ]; then
  echo "uncommit: invalid PR head/base for '$current' — refusing." >&2
  exit 2
fi

origin_url=$(git remote get-url origin 2>/dev/null || true)
origin_repository=$(gh repo view "$origin_url" --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)
if [ -z "$origin_url" ] || [ "$origin_repository" != "$repository_name" ]; then
  echo "uncommit: origin does not match the PR repository — refusing." >&2
  exit 2
fi

git fetch --quiet origin "+refs/heads/${base_branch}:refs/remotes/origin/${base_branch}"
base="origin/$base_branch"
if [ "$(git rev-list --count "$base..HEAD")" = "0" ]; then
  echo "uncommit: nothing to do — '$current' has no commits ahead of $base."
  exit 0
fi
if ! git rebase "$base"; then
  git rebase --abort 2>/dev/null || true
  echo "uncommit: rebase onto $base produced conflicts. Resolve manually, then re-run." >&2
  exit 3
fi
count=$(git rev-list --count "$base..HEAD")
if [ "$count" = "0" ]; then
  echo "uncommit: nothing to do after rebase — all commits on '$current' were already in $base."
  exit 0
fi

git reset "$base"
echo "uncommit: squashed $count commit(s) from '$current' onto PR base $base. All changes are unstaged."
echo "         Run 'git status' to see them, or '/commit' to recreate history file-by-file."
