---
name: pr
description: Create and monitor GitHub pull requests from the current branch. Use when the user asks Codex to open, create, publish, submit, or prepare a PR, watch PR checks, wait for CI, investigate failed GitHub Actions or other PR checks, and propose or implement fixes.
---

# PR

Use this skill to publish the current branch as a GitHub pull request, watch CI, and investigate failures. It assumes the branch already contains the intended commits.

## Workflow

1. Confirm branch and worktree state.
   - Run `git status --short --branch`.
   - Do not create a PR from the default branch unless the user explicitly asks.
   - If there are uncommitted changes, ask whether to commit them, leave them out, or stop.
   - Check the upstream with `git rev-parse --abbrev-ref --symbolic-full-name @{u}` when needed.

2. Create or locate the PR.
   - If a PR already exists for the branch, use it instead of creating a duplicate: `gh pr view --json number,url,headRefName,baseRefName,state`.
   - Otherwise create the PR with `gh pr create`.
   - Let `gh pr create` infer title/body from commits when appropriate; use explicit `--title`, `--body`, `--base`, or `--draft` only when the user provided those requirements or repo conventions require them.
   - If the branch has no upstream, push it with `git push -u origin HEAD` before or during PR creation.

3. Watch checks.
   - Prefer `gh pr checks --watch` to stream the PR checks until completion.
   - For non-interactive summaries, use `gh pr checks --json name,state,conclusion,link,startedAt,completedAt`.
   - If checks are pending for a long time, report the currently pending checks and continue only if the user wants to wait longer.

4. Investigate failures.
   - Identify failing checks by name and URL from `gh pr checks`.
   - For GitHub Actions checks, inspect runs and logs with `gh run list`, `gh run view`, and `gh run view --log-failed` as appropriate.
   - Map failures back to local files, commands, or tests before proposing changes.
   - Reproduce locally when practical using the same command or the closest repo-documented command.

5. Propose or implement fixes.
   - If the user asked only to investigate, summarize the failing checks, likely root cause, and concrete fixes.
   - If the user asked to fix, make scoped changes, run relevant validation, commit with the commit workflow, push, and watch checks again.

## GitHub CLI Notes

- Use elevated network access for `gh` and `git push` commands when required by the sandbox.
- Do not pass `--no-verify` to git commands unless the user explicitly requests it.
- Do not open a new PR if `gh pr view` finds an existing PR for the current branch.

## Output Expectations

- Report the PR URL, branch, and base branch.
- Report check status and name any failing checks.
- For failures, include enough log detail to justify the diagnosis without pasting large logs.
