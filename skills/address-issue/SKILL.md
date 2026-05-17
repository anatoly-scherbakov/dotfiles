---
name: address-issue
description: Investigate and implement GitHub issues from a local checkout. Use when the user asks Codex to look into, fix, address, implement, or make a PR for a specific GitHub issue number or issue URL in the current repository.
---

# Address Issue

Use this skill to take a GitHub issue from report to local implementation. It covers issue inspection, branch setup, code changes, validation, and handoff. It does not publish by default; use the GitHub publish skill only when the user asks to commit, push, or open a PR.

## Workflow

1. Resolve repository and issue.
   - Use the current git remote when the user says "this repo".
   - Fetch issue title, body, labels, and comments with the GitHub app when available.
   - Use `gh issue view` only when the connector cannot provide needed issue details.

2. Start from the issue branch.
   - Confirm the worktree status before changing branches.
   - If the checkout is on the default branch or no issue branch exists locally, run `gh issue develop <issue-number> --checkout`.
   - If the worktree has unrelated changes, do not switch branches until the user confirms how to handle them.

3. Investigate before editing.
   - Search the repo for symbols, files, generated output, tests, docs, and CI config related to the issue.
   - Check whether an existing tool already detects or validates the problem before adding bespoke guards.
   - Turn the issue into a concrete implementation plan when the requested fix is ambiguous.

4. Implement narrowly.
   - Keep changes scoped to the issue and existing repo patterns.
   - Prefer source-of-truth files over generated or archival artifacts unless the repo convention says otherwise.
   - Do not silently edit publication snapshots, vendored files, lockfiles, or generated outputs unless the issue or repo workflow requires it.

5. Validate through the repo's normal checks.
   - Run the most specific build, test, lint, or spec validation commands that cover the change.
   - If a validation command fails because a tool is missing, prefer the repo's documented installation path.
   - If network is required, request approval and rerun the same command with network access.
   - Inspect generated output when the issue is about rendered docs, links, anchors, schemas, or generated artifacts.

6. Summarize and hand off.
   - Report the branch name, changed files, validation commands, and any remaining risk.
   - Leave changes unstaged unless the user asked to commit.
   - If the user asks to publish, hand off to the GitHub publish workflow after rechecking `git status` and the intended scope.

## GitHub CLI Notes

- Prefer `gh issue develop <issue-number> --checkout` for issue implementation branches.
- Use elevated network access for `gh` commands when required by the sandbox.
- Do not use `gh issue develop` as a substitute for understanding the issue; inspect issue content first.

## Output Expectations

- For "look into issue N", provide a concise finding and proposed implementation plan.
- For "implement issue N", make the local changes and include validation results.
- For "fix and PR issue N", implement locally, then use the GitHub publish workflow to commit, push, and open a draft PR.
