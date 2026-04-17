---
name: commit
description: Commits uncommitted changes on the current branch with one file per commit and one-line messages. Use when the user asks to commit, save changes to git, or create commits from staged/unstaged changes.
---

# Commit

Commits all uncommitted changes on the current branch. One file per commit; one-line commit message per commit; no co-author trailers.

## Rules

- **One file per commit.** Never group multiple files into a single commit. Stage and commit each changed file separately.
- **One-line commit message.** No body, no bullet lists. The subject line alone describes the change in that file.
- **No co-authoring.** Do not add `Co-authored-by:` or similar trailers.
- **Issue ID prefix when known.** If an issue ID is provided or can be inferred from the current branch name, start the commit message with `[#ID]: ` (e.g. `[#171]: `). Otherwise omit the prefix.

## Resolving the issue ID

1. **User provided an issue ID** (e.g. "commit for issue 42", "commit #123") — use it.
2. **Otherwise** — run `git branch --show-current` and try to derive a number from the branch name (e.g. `171-remove-spec-folder`, `issue-123`, `42-fix-bug` → use `171`, `123`, `42`). If the branch does not clearly contain an issue ID, do not add a prefix.

**NEVER** infer the issue ID from `git log`, recent commit messages, or PR numbers in merge commits. Those belong to unrelated work. The only valid sources are the user's explicit instruction and the current branch name.

Use the resolved issue ID as `{issue_id}` in the commit message when applicable.

## Workflow

1. **List changes:**  
   `git status` (and if needed `git diff --name-only`, `git diff --name-only --cached`) to see modified/added/deleted files.

2. **For each file** (one commit per file):
   - Stage only that file: `git add -- <path>` (or `git add -u -- <path>` for deletions).
   - Inspect the change for that file (e.g. `git diff --cached -- <path>` or `git diff <path>`) and write a **single-line** message that describes what changed in that file.
   - Format: `[#{issue_id}]: <one-line description>` (include `[#{issue_id}]: ` only when issue ID is known).
   - Commit: see **Shell quoting for `git commit -m`** below (no `--no-verify` or co-author options unless the user explicitly asks).

3. Repeat until every changed file has its own commit.

### Shell quoting for `git commit -m`

Commit messages often use **backticks** around technical terms (per Message style). In **bash** and **zsh**, double-quoted strings treat `` `...` `` as **command substitution**, which **eats the backticks and runs the inner text as a command** — producing wrong or empty subjects (e.g. `` `DNOTE` `` vanishes if `DNOTE` is not a command).

**Do this:**

- When the message contains backticks, wrap the **entire** `-m` argument in **single quotes**:  
  `git commit -m '[#191]: Configure extended-profile as `DNOTE` with WG metadata'`
- Inside single quotes, backticks are **literal** (safe).

**If the message must contain a single quote (`'`):** you cannot use a single-quoted whole string easily; either use double quotes and **escape every backtick** with backslash (`\``), or use `git commit -F` with a here-doc / temp file.

**Default for agents:** prefer `git commit -m '...'` whenever the subject includes backticks; avoid `git commit -m "...\`...\`..."` unless you need embedded single quotes.

## Message style

- Imperative, present tense: "Add X", "Fix Y", "Update Z in README".
- Describe the change in **that file** (e.g. "Point spec source to index.html", "Regenerate manifest from JSON and generator").
- Use backticks around code, syntax, or technical terms (e.g. `@value`, `application/ld+yaml`, `grep`). When passing that text to `git commit -m` in the shell, use **single-quoted** `-m` so those backticks are not executed (see **Shell quoting** above).

## Examples

- Branch `171-remove-spec-folder-match-other-repos`, change in `Makefile`:  
  `[#171]: Use system Chrome for ReSpec when available`

- Branch `171-remove-spec-folder-match-other-repos`, change in `tests/manifest.jsonld`:  
  `[#171]: Update spec URL in manifest description to top-level`

- Branch `main`, change in `README.md`:  
  `Fix typo in installation section`

- Quote date values in YAML test, change in `tests/cases/html/stream.yamlld`:  
  `[#83]: Quote dates in \`@value\` fields in stream expected output`

- Multiple files changed: create one commit per file, each with its own one-line message describing that file’s change.
