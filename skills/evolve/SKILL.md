---
name: evolve
description: Evolve a project from the current session by discovering the project's goal, extracting agent errors and project learnings, and persisting approved guidance into AGENTS.md files or relevant skill files. Use when the user asks to evolve, retro, run a retrospective, capture learnings, persist session lessons, update project guidance, or reduce repeated friction.
---

# Evolve

Evolves the current project by turning useful session learnings into durable
guidance. First understand the project's goal (and any relevant skill goals),
then extract only learnings that help better achieve those goals. Ask which
learnings to keep, then write approved learnings into the right `AGENTS.md`
files or relevant skill files.

Run at the end of any working session where the agent made non-obvious
mistakes, learned something about the project, or the user wants to prevent
repeated friction.

## Workflow

### Step 1 — Understand the project goal

Discover the current project's goal before extracting learnings. Prefer explicit
statements over inference:

1. Read `docs/goal.md` if it exists.
2. Read `README.md` and look for goal, purpose, mission, motivation, or project
   overview sections.
3. Read applicable `AGENTS.md` files:
   - root `AGENTS.md`
   - any subdirectory `AGENTS.md` that owns files likely to be updated
   - any guidance files explicitly referenced by those files
4. For each skill that was active in the session or is likely to receive
   learnings — invoked via `/skill`, edited under `skills/<name>/`, or referenced
   in the conversation — read its `SKILL.md` and look for a `## Goal` section.

If multiple goal statements exist, treat the most specific relevant statement as
primary and use broader statements as context. When a learning targets a skill
file, that skill's `## Goal` (if present) is more specific than the project goal
for goal_fit filtering. If no explicit goal exists, infer a provisional goal from
the README and project structure, and label it as inferred when presenting
learnings.

Use the goal as a filter:

- Prefer learnings that prevent repeated mistakes, setup friction, workflow
  failures, or agent misbehavior.
- Prefer learnings that make future work faster, safer, or more consistent with
  the project's purpose.
- Skip trivia, one-off history, and preferences that do not improve future
  project outcomes.

### Step 2 — Extract learnings from the current conversation

The skill runs inside the active session, so the full conversation is already in
context. Review it directly for:

- **Corrections**: user said "no", "wrong", "stop", "actually...", or
  redirected the agent
- **Abandoned approaches**: agent tried something, user overrode it
- **Surprises**: project structure, conventions, or constraints that were not
  obvious from the code
- **Repeated mistakes**: the agent made the same error more than once
- **Confirmed non-obvious choices**: user accepted an unusual decision without
  pushback and it supports the project goal
- **Friction signals**: the session exposed a recurring setup, workflow, tool,
  or agent behavior problem

For each learning, build a record:

```
summary:        one-line description
detail:         what happened and why it matters for future agents
goal_fit:       how this helps achieve the discovered goal — use the target
                skill's `## Goal` when the learning maps to a skill file;
                otherwise use the project goal
relevant_paths: files or directories this learning applies to (empty = whole project)
type:           mistake | convention | discovery | confirmation | friction
```

Skip learnings that are already documented in existing `AGENTS.md` files,
`CLAUDE.md`, or relevant skill files.

### Step 3 — Map each learning to the right persistence target

- Learning about a reusable skill's workflow, prompts, tool use, or output
  conventions -> inspect that skill directory and propose the most relevant
  existing skill file as the target.
- `relevant_paths` is empty or project-wide -> root `AGENTS.md`
- All paths are within one subdirectory (e.g. everything under `tests/`) ->
  `tests/AGENTS.md`
- Paths span multiple unrelated directories -> split into separate entries, one
  per directory

Prefer updating a skill over `AGENTS.md` when the learning only matters while
that skill is active. Do not assume auxiliary skill filenames exist; inspect the
skill directory first. If the skill only has `SKILL.md`, target `SKILL.md`. When
inspecting a skill directory, read its `## Goal` section if not already
captured in Step 1.

### Step 4 — Present learnings for approval

Show the discovered project goal first. If it was inferred, say so clearly. If
any relevant skills have a `## Goal` section, show those too (name the skill and
quote the goal text).

Then show a summary table:

| # | Summary | Type | Target file | Goal fit |
|---|---------|------|-------------|----------|
| 1 | ... | mistake | `skills/example/SKILL.md` | ... |
| 2 | ... | convention | `AGENTS.md` | ... |

For each learning, show **summary**, **detail**, **goal fit**, and **proposed
target** so the user has enough context to decide.

Then ask **one multi-select question** with all learnings as options. Use the
host's structured-question tool with multi-select enabled when available (e.g.
`AskQuestion` with `allow_multiple: true`); otherwise fall back to asking the
user to list the numbers to keep in plain text. The only choice is keep-or-skip
-- do not offer per-item edit or move actions.

**If the user declines, dismisses, or skips the approval question** (including
closing the prompt without selecting anything): treat that as **reject all** --
persist nothing, skip Steps 5-6, and go straight to Step 7 reporting zero
approved learnings. Do not re-ask in plain text, do not write any files, and do
not assume implicit approval.

If no learnings were extracted, skip the question and report "no clusters found"
/ zero learnings.

Accumulate the approved (checked) learnings grouped by target file. Discard the
rest.

### Step 5 — Write approved learnings into target files

For each target `AGENTS.md`:

- **File doesn't exist**: create it with a `# <Directory> guidance` heading and
  the new entries
- **File exists**: find the appropriate section and append, or create a new
  section

Write entries as short, imperative instructions aimed at the agent -- not prose,
not history. Example:

> - Do not run `make test` directly; use `pytest tests/` with the virtualenv
>   activated.

After writing each file, check its line count. If it exceeds **80 lines**, flag
it and offer to consolidate or prune redundant entries. Ask before removing
anything.

For each target skill file:

- Preserve the skill's existing structure and terminology.
- Add short, imperative instructions aimed at future agents, not session
  history.
- Place the instruction in the most relevant existing section, or create a
  concise section if none fits.
- Do not add project-specific facts to a general-purpose skill unless they
  describe reusable behavior for that skill.

### Step 6 — Maintain the reference chain

After all writes are done, if any `AGENTS.md` files were created, deleted, or
updated:

**Root `AGENTS.md`**: ensure it has a `## Subdirectory guidance` section that
lists every child `AGENTS.md` in the project tree. Scan the tree for `AGENTS.md`
files. Add newly created ones; remove links to files that no longer exist. Never
duplicate an entry.

Example section:

```markdown
## Subdirectory guidance

- [tests/AGENTS.md](tests/AGENTS.md) - test runner conventions and fixture layout
- [src/AGENTS.md](src/AGENTS.md) - module structure and import rules
```

**Root `CLAUDE.md`**: ensure it exists and contains exactly this line:

```
See [AGENTS.md](AGENTS.md) for project-specific agent guidance.
```

- If `CLAUDE.md` doesn't exist: create it with that single line
- If it exists but lacks this line: prepend it
- Do not alter any other existing content in `CLAUDE.md`

### Step 7 — Report

Print a brief summary:

- Discovered goal source(s), including any skill `## Goal` sections read; or
  "goal inferred" if no explicit goal existed
- N learnings extracted, M approved, K skipped (if approval was declined, M = 0
  and note "user declined to persist")
- Files created / updated (list them, or "none" when approval was declined)
- Any files now near the 80-line limit

## Constraints

- **Never write silently.** Every write is preceded by explicit user approval in
  Step 4. Declining or skipping the approval question means persist nothing.
- **Goal-aware, not project-specific.** Discover each project's goal from local
  files at runtime — including `## Goal` sections in relevant `SKILL.md` files.
  Do not hardcode one project's goal into this skill.
- **Size guard.** Flag any `AGENTS.md` exceeding ~80 lines and offer
  consolidation; always ask before pruning.
- **Minimal `CLAUDE.md`.** Only ensure the single reference line exists -- never
  accumulate other content in `CLAUDE.md`.
- **Idempotent.** Re-running `evolve` must not duplicate the
  `## Subdirectory guidance` section or any entries within it.
- **Skill targeting.** Do not force skill-specific learnings into `AGENTS.md`;
  propose skill file targets when the learning improves a reusable skill
  workflow.
- **No JSONL parsing.** The conversation is already in context; never try to
  read session transcript files from disk.

## AGENTS.md layout and splitting

When evolve surfaces growth pressure, a split request, or any `AGENTS.md` file
exceeds **~80 lines**, apply this layout before adding more rules to root.

### What stays in root `AGENTS.md`

- Rules that apply repo-wide (environment, linting, git workflow pointers)
- `## Subdirectory guidance` -- an index linking to every other `AGENTS.md` in
  the tree
- Pointers to dedicated skills (e.g. commit formatting -> `commit` skill), not
  duplicated skill content

### Where to move rules

Move rules to the `AGENTS.md` in the directory that **owns** the code or
content:

| Scope | Target |
|-------|--------|
| `docs/` authoring, MkDocs, prose | `docs/AGENTS.md` |
| Jeeves commands under `jeeves/` | `jeeves/AGENTS.md` |
| Tests under `tests/` | `tests/AGENTS.md` |
| Deep howto enclaves | that howto's `AGENTS.md` |

Assign by **who defines or runs the command**, not by which page you happen to be
editing (e.g. `j serve` -> `jeeves/AGENTS.md`, not `docs/AGENTS.md`).

### Splitting rules

- Keep existing rule IDs (F, D, A, ...) when moving blocks; change file location
  only, do not renumber.
- Delete rules superseded by a skill; do not copy them into a subdirectory file.
- After creating or moving subdirectory files, update root
  `## Subdirectory guidance` to list **every** `AGENTS.md` under the repo (scan
  the tree; no duplicates).
- If a file is still over ~80 lines after a split, flag it and propose a
  follow-up split -- do not prune without asking.

### `AGENTS.md` under `docs/` (MkDocs)

MkDocs publishes every `*.md` in `docs_dir` unless excluded. For projects using
MkDocs:

- Prefer the standard filename `AGENTS.md` (not dotfiles) for agent discovery via
  root links.
- Add `**/AGENTS.md` to `exclude_docs` in `mkdocs.yml` so guidance never ships as
  site pages.
- Document the exclusion in `docs/AGENTS.md` once configured.

When evolve creates `docs/AGENTS.md`, verify `exclude_docs` includes
`**/AGENTS.md` before finishing Step 6.
