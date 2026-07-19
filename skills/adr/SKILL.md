---
name: adr
description: Use when the user invokes /adr or asks to draft, brainstorm, or document an architecture decision record (ADR). Conducts a two-stage brainstorm interview (option discovery, then option exclusion) and writes a MkDocs-Material-formatted ADR. Project-agnostic — detects the project's ADR location, leaves filename naming to the user.
---

# ADR

## Goal

Goal of this skill is to facilitate rational, data-driven decision making via the framework of Architecture Decision Records.

Guides the user through writing an Architecture Decision Record. The output is a single Markdown file targeting **MkDocs Material**, with ADR metadata in frontmatter and a decision shape chosen from the templates in [templates/](templates/README.md).

The skill is structured as a **two-stage brainstorm**: first enumerate every option without judgment, then walk the list and exclude. After the file is written, the skill stops — no git staging, no commit. The user reviews and saves manually.

## When to use

- The user types `/adr`.
- The user says "let's draft an ADR / decision record" or similar.
- The user is weighing alternatives and wants the reasoning preserved.

Do **not** invoke this skill for general note-taking, README updates, or post-mortems — only for decisions where alternatives were considered.

## Required resources

Always load these bundled resources before drafting or editing an ADR:

- [rules.md](rules.md) — mandatory ADR style, structure, and formatting rules.
- [templates/README.md](templates/README.md) — template catalog only; load the chosen template file for everything else.
- [writer-prompt.md](writer-prompt.md) — instructions for the role that edits the ADR file.
- [reviewer-prompt.md](reviewer-prompt.md) — instructions for the read-only review role.

## Mandatory two-role workflow

Every ADR file mutation must use two separate roles:

1. **Writer** — reads the target file, `rules.md`, and the chosen template file; edits the ADR Markdown file in place per `writer-prompt.md`.
2. **Reviewer** — reads the target file, `rules.md`, and the chosen template file; does not edit files, checks every rule per `reviewer-prompt.md` (including a concise scan of the ADR), and reports findings.

When the runtime permits subagents, run the writer and reviewer as separate agents using the bundled prompt files. The writer owns edits to the target ADR file. The reviewer owns no files and must remain read-only.

If the runtime does not permit subagents, do **not** silently fall back to an ordinary single-role ADR write. Stop and tell the user that this skill requires the writer/reviewer workflow and needs subagent authorization or a runtime that supports it.

After every writer pass, run the reviewer. If the reviewer reports blockers, the writer fixes them and the reviewer runs once more. If blockers remain after the second reviewer pass, summarize them and ask the user how to proceed.

## Workflow

### Stage 0 — framing

1. **Resolve the file location** before asking anything else:
   - If `docs/decisions/` exists in the current project, default new file there.
   - Otherwise, if `docs/blog/` contains posts with `tags: [decision]` in frontmatter, default there.
   - Otherwise, ask the user for a directory.

2. **Working title.** Propose an **outcome-shaped** one-line title from the user's stated goal, then ask the user to accept or revise it. Enforce these rules (R09, R29):
   - Must start with a **verb** that names the decision outcome (Adopt, Require, Replace, Drop, Host, Implement, Publish, Use…).
   - Must describe the **raw decision**, not the activity of writing the ADR. Reject meta titles such as `Choose where to…`, `Decide between…`, `Pick a…`.
   - No `Decision:` prefix.
   - While the choice is open (`status: undecided`), keep the same outcome sentence and put Unicode ellipsis `…` (U+2026) in the unknown slot(s). Example: language still open → `Implement YAML-LD support in …` (not `Choose a programming language for YAML-LD`).
   - When the ADR becomes `status: decided`, remove every `…` and fill in the factual outcome in both frontmatter `title:` and H1. Example: `Implement YAML-LD support in Rust`.

   If the user's draft title is meta (`Choose payment provider`), rewrite it to outcome shape with `…` (`Pay with …` / `Use … for payments`) and confirm before continuing.

3. **Filename.** Propose a kebab-case slug from the title (e.g. `host-yaml-ld-support-in.md` or `implement-yaml-ld-support-in.md`), then ask the user to accept or revise it. **Do not impose a date prefix** — naming is the user's call. Prefer slugs that match the outcome shape; do not force a `choose-` prefix.

4. **Context.** Draft 2–4 context sentences from the user's stated goal, then ask the user to accept or revise them. The context must answer: what's the situation, and why is a decision needed now? Keep this scoped to the **one** decision (rule R01 — one page, one idea; cross-link other ADRs instead of inlining their detail).

5. **Template.** Show [templates/README.md](templates/README.md) and ask which row fits. Read that template file's `{# ... #}` header comment before continuing — it is the only source for shape, representation, and Stage 2–3 behavior.

6. **Write an initial draft immediately.** Once the file location, title, filename, context, and template choice are stable enough, delegate to the **writer** subagent with a concrete edit spec to create the ADR file from the chosen template skeleton. Run the **reviewer** subagent after the writer pass. Continue option discovery, exclusions, research, costs, and final choice by delegating in-place edits to the writer (with reviewer after each pass) instead of holding the evolving ADR only in chat.

### Stage 1 — option discovery

Propose an initial list of **every** option or capability you can infer from the user's stated goal, including partial or likely-bad options. Then ask the user to accept, remove, rename, or add items.

> Here is the initial option list I see. I'll include weak and partial options too so we can narrow them down next. What should I add, remove, or rename?

Capture each as a bare label only — no Pros, no Contras, no commentary yet. The point of this stage is **breadth**: judging too early kills good options that look weak at first glance.

Keep alternatives at the right level of abstraction. An alternative must be a capable solution shape for the decision at hand, not merely a downstream tool, implementation detail, output backend, or capability that only makes sense after the main architecture is chosen. If a candidate does not solve the core problem by itself, move it to consequences, implementation steps, follow-up decisions, or reject it with that reason.

If the user gives options first, merge them with your inferred options before asking for confirmation. Do not make the user solely responsible for option discovery.

When the user says the list is complete, read it back and ask whether anything else comes to mind. Then delegate a writer pass to add the confirmed option labels to the ADR, run the reviewer, and move to Stage 2.

### Stage 2 — option exclusion

Drive the elimination — propose exclusions actively rather than surveying each option. For each option you'd reject, ask:

> I propose to exclude **[option name]** because [one-line reason]. Do you agree?

Frame as a two-option structured question: a "Yes, exclude" path plus a free-text path so the user can push back with a reason. Batch multiple obvious exclusions into one prompt when you can; don't drip-feed.

Do **not** ask "keep / drop / undecided?" for every option — that's a survey, not facilitation. Take a position on each option you can defend; let the user push back on the ones you got wrong.

If the user asks for a Socratic or directed-question method, switch from broad option dumping to one concise question at a time. Each question should expose one constraint, priority, or tradeoff needed to classify the alternatives, then use the answer to narrow or revise the ADR.

**If excluded:**
- Capture the user's accepted reason (or your proposed reason if they accepted it as-is).
- Record the exclusion per the chosen template file's `{# ... #}` header comment.

**If keep or undecided:**
- Follow the chosen template file's `{# ... #}` header comment.

After every option is processed:
- Follow the chosen template file's `{# ... #}` header comment for closing open outcomes and frontmatter status.

If zero options remain kept, stop and ask the user to revisit Stage 1 — the exclusion was too aggressive.

After processing options, delegate a writer pass to update the ADR with exclusions, kept alternatives, and status markers. Run the reviewer after the writer pass.

### Stage 3 — consequences

Ask: **what changes after this decision lands?** Capture as a bullet list. If there are concrete implementation steps, render them as a task list (`- [ ]`) per rule R21. Follow the chosen template file's `{# ... #}` header comment for any template-specific Consequences requirements.

Delegate a writer pass to add consequences. Run the reviewer after the writer pass.

### Stage 4 — finalize the file

Pick the matching template file from [templates/](templates/README.md) and delegate to the **writer** subagent to fill in and update `<resolved-directory>/<slug>.md`. If an initial draft already exists from Stage 0, the writer edits that file in place. Run the **reviewer** subagent after the writer pass.

Resolve frontmatter `date` to today (YYYY-MM-DD) and `author` from `git config user.name` (fallback: ask the user if detection fails). No need to ask the user about either unless detection fails — these are metadata, not decisions.

**Print only the relative file path** of the new file and stop. Do not stage, do not commit, do not open an editor.

## Templates

Per-template shape and usage live only in `templates/<name>.md` (`{# ... #}` header comment). [templates/README.md](templates/README.md) is the catalog. Do not duplicate template content anywhere else in this skill.

## Rules

ADR style and structure rules live in [rules.md](rules.md). Enforce them via the writer and reviewer subagents — do not apply them silently in the orchestrator alone.

## Constraints

- **Writer/reviewer for every file mutation.** The orchestrator facilitates Stages 0–3 with the user; all ADR file edits go through the writer, followed by the reviewer. Do not edit ADR files directly when subagents are available.
- **Two stages, in order.** Never add judgment commentary during option discovery (Stage 1). Discovery is breadth-only; judgment lives in Stage 2 per the chosen template.
- **No date in filenames.** The user's naming is final — never insert `YYYY-MM-DD.` prefixes.
- **Stop after writing.** Do not run `git add`, do not run `git commit`, do not invoke `/commit`. Print the file path and exit the workflow.
- **Never decide for the user.** Keep `status: undecided` until the user explicitly chooses or approves — per the chosen template file.
- **One ADR, one file.** If the user starts describing two unrelated decisions, stop and ask which one this ADR is about. The other becomes a separate `/adr` invocation.
