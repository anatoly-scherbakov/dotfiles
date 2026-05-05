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

Then walk through each learning individually. For each one, show:
- **Summary** and **detail**
- **Proposed target**: which `AGENTS.md` or skill file it would go into

The user can respond:
- **keep** — approve as proposed
- **skip** — discard
- **edit** — reword before writing
- **move** — change the target file or directory

Accumulate approved learnings grouped by target file.

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

- N learnings extracted, M approved, K skipped
- Files created / updated (list them)
- Any files now near the 80-line limit

## Constraints

- **Never write silently.** Every write is preceded by user approval in Step 3.
- **Size guard.** Flag any `AGENTS.md` exceeding ~80 lines and offer consolidation; always ask before pruning.
- **Minimal `CLAUDE.md`.** Only ensure the single reference line exists — never accumulate other content there.
- **Idempotent.** Re-running `/retro` must not duplicate the `## Subdirectory guidance` section or any entries within it.
- **Skill targeting.** Do not force skill-specific learnings into `AGENTS.md`; propose skill file targets when the learning improves a reusable skill workflow.
- **No JSONL parsing.** The conversation is already in context; never try to read session transcript files from disk.
