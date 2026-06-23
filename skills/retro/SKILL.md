---
name: retro
description: Review the current session for agent errors and project learnings, then persist approved learnings into AGENTS.md files or relevant skill files.
---

# Retro

Reviews the current session for mistakes and discoveries, asks you which learnings to keep, and writes them into the right `AGENTS.md` files or relevant skill files. Also maintains the `CLAUDE.md` → `AGENTS.md` → subdirectory `AGENTS.md` discovery chain when `AGENTS.md` files are changed.

Run at the end of any working session where the agent made non-obvious mistakes, learned something about the project's conventions, or you want to prevent a repeated error.

## Workflow

### Step 1 — Extract learnings from the current conversation

The skill runs inside the active session — the full conversation is already in context. Review it directly for:

- **Corrections**: user said "no", "wrong", "stop", "actually…", or redirected the agent
- **Abandoned approaches**: agent tried something, user overrode it
- **Surprises**: project structure, conventions, or constraints that weren't obvious from the code
- **Repeated mistakes**: the agent made the same error more than once
- **Confirmed non-obvious choices**: user accepted an unusual decision without pushback — worth reinforcing so it's repeated next time

For each learning, build a record:

```
summary:        one-line description
detail:         what happened and why it matters for future agents
relevant_paths: files or directories this learning applies to (empty = whole project)
type:           mistake | convention | discovery | confirmation
```

Skip learnings that are already documented in existing `AGENTS.md` files, `CLAUDE.md`, or relevant skill files.

### Step 2 — Map each learning to the right persistence target

- Learning about a reusable skill's workflow, prompts, tool use, or output conventions → inspect that skill directory and propose the most relevant existing skill file as the target.
- `relevant_paths` is empty or project-wide → root `AGENTS.md`
- All paths are within one subdirectory (e.g. everything under `tests/`) → `tests/AGENTS.md`
- Paths span multiple unrelated directories → split into separate entries, one per directory

Prefer updating a skill over `AGENTS.md` when the learning only matters while that skill is active. Do not assume auxiliary skill filenames exist; inspect the skill directory first. If the skill only has `SKILL.md`, target `SKILL.md`.

### Step 3 — Present learnings for approval

Show a summary table:

| # | Summary | Type | Target file |
|---|---------|------|-------------|
| 1 | ... | mistake | `skills/example/SKILL.md` |
| 2 | ... | convention | `AGENTS.md` |

For each learning, show **summary**, **detail**, and **proposed target** (which `AGENTS.md` or skill file it would go into) so the user has enough context to decide.

Then ask **one multi-select question** with all learnings as options. Use the host's structured-question tool with multi-select enabled when available (e.g. `AskQuestion` with `allow_multiple: true`); otherwise fall back to asking the user to list the numbers to keep in plain text. The only choice is keep-or-skip — do not offer per-item edit or move actions.

**If the user declines, dismisses, or skips the approval question** (including closing the prompt without selecting anything): treat that as **reject all** — persist nothing, skip Steps 4–5, and go straight to Step 6 reporting zero approved learnings. Do not re-ask in plain text, do not write any files, and do not assume implicit approval.

If no learnings were extracted, skip the question and report "no clusters found" / zero learnings.

Accumulate the approved (checked) learnings grouped by target file. Discard the rest.

### Step 4 — Write approved learnings into target files

For each target `AGENTS.md`:

- **File doesn't exist**: create it with a `# <Directory> guidance` heading and the new entries
- **File exists**: find the appropriate section and append, or create a new section

Write entries as short, imperative instructions aimed at the agent — not prose, not history. Example:

> - Do not run `make test` directly; use `pytest tests/` with the virtualenv activated.

After writing each file, check its line count. If it exceeds **80 lines**, flag it and offer to consolidate or prune redundant entries. Ask before removing anything.

For each target skill file:

- Preserve the skill's existing structure and terminology.
- Add short, imperative instructions aimed at future agents, not session history.
- Place the instruction in the most relevant existing section, or create a concise section if none fits.
- Do not add project-specific facts to a general-purpose skill unless they describe reusable behavior for that skill.

### Step 5 — Maintain the reference chain

After all writes are done, if any `AGENTS.md` files were created, deleted, or updated:

**Root `AGENTS.md`**: ensure it has a `## Subdirectory guidance` section that lists every child `AGENTS.md` in the project tree. Scan the tree for `AGENTS.md` files. Add newly created ones; remove links to files that no longer exist. Never duplicate an entry.

Example section:

```markdown
## Subdirectory guidance

- [tests/AGENTS.md](tests/AGENTS.md) — test runner conventions and fixture layout
- [src/AGENTS.md](src/AGENTS.md) — module structure and import rules
```

**Root `CLAUDE.md`**: ensure it exists and contains exactly this line:

```
See [AGENTS.md](AGENTS.md) for project-specific agent guidance.
```

- If `CLAUDE.md` doesn't exist: create it with that single line
- If it exists but lacks this line: prepend it
- Do not alter any other existing content in `CLAUDE.md`

### Step 6 — Report

Print a brief summary:

- N learnings extracted, M approved, K skipped (if approval was declined, M = 0 and note "user declined to persist")
- Files created / updated (list them, or "none" when approval was declined)
- Any files now near the 80-line limit

## Constraints

- **Never write silently.** Every write is preceded by explicit user approval in Step 3. Declining or skipping the approval question means persist nothing.
- **Size guard.** Flag any `AGENTS.md` exceeding ~80 lines and offer consolidation; always ask before pruning.
- **Minimal `CLAUDE.md`.** Only ensure the single reference line exists — never accumulate other content there.
- **Idempotent.** Re-running `/retro` must not duplicate the `## Subdirectory guidance` section or any entries within it.
- **Skill targeting.** Do not force skill-specific learnings into `AGENTS.md`; propose skill file targets when the learning improves a reusable skill workflow.
- **No JSONL parsing.** The conversation is already in context; never try to read session transcript files from disk.

## AGENTS.md layout and splitting

When retro surfaces growth pressure, a split request, or any `AGENTS.md` file exceeds **~80 lines**, apply this layout before adding more rules to root.

### What stays in root `AGENTS.md`

- Rules that apply repo-wide (environment, linting, git workflow pointers)
- `## Subdirectory guidance` — an index linking to every other `AGENTS.md` in the tree
- Pointers to dedicated skills (e.g. commit formatting → `commit` skill), not duplicated skill content

### Where to move rules

Move rules to the `AGENTS.md` in the directory that **owns** the code or content:

| Scope | Target |
|-------|--------|
| `docs/` authoring, MkDocs, prose | `docs/AGENTS.md` |
| Jeeves commands under `jeeves/` | `jeeves/AGENTS.md` |
| Tests under `tests/` | `tests/AGENTS.md` |
| Deep howto enclaves | that howto's `AGENTS.md` |

Assign by **who defines or runs the command**, not by which page you happen to be editing (e.g. `j serve` → `jeeves/AGENTS.md`, not `docs/AGENTS.md`).

### Splitting rules

- Keep existing rule IDs (F, D, A, …) when moving blocks; change file location only, do not renumber.
- Delete rules superseded by a skill; do not copy them into a subdirectory file.
- After creating or moving subdirectory files, update root `## Subdirectory guidance` to list **every** `AGENTS.md` under the repo (scan the tree; no duplicates).
- If a file is still over ~80 lines after a split, flag it and propose a follow-up split — do not prune without asking.

### `AGENTS.md` under `docs/` (MkDocs)

MkDocs publishes every `*.md` in `docs_dir` unless excluded. For projects using MkDocs:

- Prefer the standard filename `AGENTS.md` (not dotfiles) for agent discovery via root links.
- Add `**/AGENTS.md` to `exclude_docs` in `mkdocs.yml` so guidance never ships as site pages.
- Document the exclusion in `docs/AGENTS.md` once configured.

When retro creates `docs/AGENTS.md`, verify `exclude_docs` includes `**/AGENTS.md` before finishing Step 5.
