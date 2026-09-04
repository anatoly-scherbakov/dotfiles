---
name: retro
description: Learn from a recognized mistake in the moment. Reads Claude Code's queued bug-report drafts under ~/.claude/feedback/drafts and, for each, analyzes the reason behind the mistake and turns it into one line of durable agentic guidance at the right target — user-global ~/.claude/CLAUDE.md (via ~/dotfiles/agents/AGENTS.md), a project AGENTS.md/CLAUDE.md, or a specific skill — confirms it, applies it, then deletes the draft. Use at the end of any turn in which a bug-report draft was filed, or on demand to drain the backlog.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(rm /home/anatoly/.claude/feedback/drafts/:*), AskUserQuestion
---

# Retro

Turn each recognized mistake into durable guidance, one at a time, in the moment.
Claude Code files a structured self-critique **draft** the instant it recognizes
a mistake worth a bug report; this skill reads those drafts, works out *why* each
happened, and writes the smallest guidance that would have prevented it into the
right file. Applying a lesson then deletes its draft, redirecting it from a bug
report into this knowledge base.

Run this at the end of any turn in which a draft was filed (the global
`## Learning from mistakes` guidance arms that), or on demand to drain the
backlog.

## Goal

Reduce recurrence of agent mistakes by converting each into the smallest durable
piece of agentic guidance that would have prevented it — placed where a future
agent will actually read it. Symptoms are not the target; the **cause** is.

## Workflow

### Step 1 — List pending drafts

Drafts live at `~/.claude/feedback/drafts/*.json`. Each is a queued bug report.

1. Glob `~/.claude/feedback/drafts/*.json`. If the directory does not exist or
   holds no `.json` files, report "No pending drafts to learn from." and stop.
   The path is internal and undocumented, so **degrade gracefully** — never error
   because it is absent or shaped differently than expected.
2. Read the handled-ledger `~/.claude/feedback/.retro-handled` if present (one
   `draft_id` per line). Drop any draft whose `draft_id` is already listed — those
   were reviewed and deliberately skipped, so do not re-offer them.
3. If nothing remains after filtering, report "No new drafts to learn from." and
   stop.

### Step 2 — Read each draft and analyze the reason

For each remaining draft, parse its JSON. The relevant fields:

- `title` — one-line statement of the mistake.
- `failure_mode` — e.g. `overconfidence_and_hallucination`, `unwanted_scope`,
  `context_and_memory`, `stopping_short`. The class of error.
- `details` — a markdown body with **What happened / What the user said / Repro /
  Evidence / Cause** labels. The **`**Cause:**`** line is the root reason and the
  primary raw material for the guidance.
- `cwd` — the project the mistake happened in. Guidance targeting a project must
  use *this* path, which may differ from the current working directory.
- `transcript_ref.session_file` — the full session JSONL. Consult it **only** if
  the draft's own Cause is too thin to derive a lesson, and read narrowly; the
  draft summary is normally sufficient and self-contained.

Derive, from the cause, a single imperative lesson: the rule that — had it been in
front of the agent — would have prevented this mistake. Keep it general enough to
catch the class of error, specific enough to be actionable.

### Step 3 — Choose the persistence target

Classify the lesson's scope, then pick the file. Reuse the mapping rules and the
`# <Directory> guidance` conventions from `~/dotfiles/skills/evolve/SKILL.md`
(its Step 3 and its "AGENTS.md layout and splitting" section) rather than
reinventing them.

- **Cross-project agent behavior** (how the agent reasons or conducts itself
  regardless of repo — verification habits, attribution discipline, scope
  restraint, applying its own memory) → user-global `~/dotfiles/agents/AGENTS.md`,
  which flows into `~/.claude/CLAUDE.md`.
- **Project-specific** (only matters inside one repo) → that project's
  `AGENTS.md`/`CLAUDE.md` at the draft's `cwd` — root, or the subdirectory that
  owns the relevant files. If the `cwd` path no longer exists, fall back to
  user-global guidance or, if it does not generalize, treat the draft as a
  Dismiss candidate in Step 4.
- **Only-while-a-skill-is-active** (the lesson only applies when a given skill is
  driving) → that skill's file. Inspect the skill directory first; fall back to
  its `SKILL.md`.

Skip a draft's write if equivalent guidance already exists in the chosen target
(surface it as "already documented" in Step 4 and offer Dismiss).

### Step 4 — Propose and confirm, one draft at a time

Never batch. For each draft in turn, show:

- the mistake (`title`) and the extracted **cause**;
- the chosen **target file**;
- the proposed **one-line imperative guidance**.

Then ask a single-draft question (AskUserQuestion) with three options:

- **Apply** — write the guidance and delete the draft.
- **Skip (keep to send)** — leave the draft queued so it can still be sent to
  Anthropic; record it in the handled-ledger so it is not re-offered.
- **Dismiss** — delete the draft without writing anything (it was noise, or
  already documented).

The free-text option lets the user reword the guidance or redirect the target
before applying.

### Step 5 — Act on the choice

- **Apply**
  - If the target file does not exist, create it with a `# <Directory> guidance`
    heading; otherwise append to the most relevant section (create a concise
    section if none fits). Write a short imperative instruction aimed at the agent
    — not prose, not history.
  - After writing, if the file exceeds **80 lines**, flag it and offer to
    consolidate or prune; ask before removing anything.
  - Confirm the guidance actually landed — Read the target file back and check the
    new line is present — **before** deleting the draft. The draft is the only
    copy of the lesson; never delete it on the strength of an unverified write.
  - Then delete the draft:
    `rm /home/anatoly/.claude/feedback/drafts/<draft_id>.json`.
- **Skip** — add `<draft_id>` on its own line to
  `~/.claude/feedback/.retro-handled` (Read the file if it exists, then Write it
  back with the id appended; create it if missing). Leave the draft in place.
- **Dismiss** — `rm /home/anatoly/.claude/feedback/drafts/<draft_id>.json`. No
  write to any guidance file.

### Step 6 — Maintain the reference chain

Only when a **new project `AGENTS.md`** was created in Step 5, follow evolve's
Step 6: ensure the project's root `AGENTS.md` has an idempotent
`## Subdirectory guidance` index and that root `CLAUDE.md` carries the single
`See [AGENTS.md](AGENTS.md) ...` pointer line. Writes to the user-global
`~/dotfiles/agents/AGENTS.md` need no reference chain — it is already wired to
`~/.claude/CLAUDE.md`.

### Step 7 — Report

Print a brief summary: for each draft, the target file and the action taken
(applied / skipped / dismissed); any file now near the 80-line limit; and how
many drafts remain queued (skipped) versus cleared.

## Constraints

- **Confirm each write.** One draft, one question, one decision. Never apply in
  bulk and never write without explicit approval for that draft.
- **One lesson per draft, at most.** Do not fan a single draft into several
  entries.
- **Deleting is irreversible and forgoes the bug report.** Apply and Dismiss
  permanently remove the draft — the deliberate "redirect into my knowledge base
  instead of sending it" choice. Only **Skip** preserves the option to send the
  report to Anthropic later.
- **Degrade gracefully on the drafts path.** `~/.claude/feedback/drafts/` is
  internal and undocumented; if it is missing, empty, or an entry does not parse,
  say so and move on — never fail the turn over it.
- **Target the draft's `cwd`, not the current repo.** A draft may come from a
  different project or an earlier session.
- **Do not duplicate existing guidance.** If the target already says it, Dismiss.
