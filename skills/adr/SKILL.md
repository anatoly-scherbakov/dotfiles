---
name: adr
description: Use when the user invokes /adr or asks to draft, brainstorm, or document an architecture decision record (ADR). Conducts a two-stage brainstorm interview (option discovery, then option exclusion) and writes a MkDocs-Material-formatted ADR. Project-agnostic — detects the project's ADR location, leaves filename naming to the user.
---

# ADR

Guides the user through writing an Architecture Decision Record. The output is a single Markdown file targeting **MkDocs Material**, with ADR metadata in frontmatter and either tabs (mutually exclusive alternatives) or a status table (multi-select alternatives), depending on the decision shape.

The skill is structured as a **two-stage brainstorm**: first enumerate every option without judgment, then walk the list and exclude. After the file is written, the skill stops — no git staging, no commit. The user reviews and saves manually.

## When to use

- The user types `/adr`.
- The user says "let's draft an ADR / decision record" or similar.
- The user is weighing alternatives and wants the reasoning preserved.

Do **not** invoke this skill for general note-taking, README updates, or post-mortems — only for decisions where alternatives were considered.

## Workflow

### Stage 0 — framing

1. **Resolve the file location** before asking anything else:
   - If `docs/decisions/` exists in the current project, default new file there.
   - Otherwise, if `docs/blog/` contains posts with `tags: [decision]` in frontmatter, default there.
   - Otherwise, ask the user for a directory.

2. **Working title.** Propose a neutral one-line title from the user's stated goal, then ask the user to accept or revise it. Enforce these rules:
   - Must start with a **verb** (Choose, Adopt, Require, Replace, Drop, Read, Limit, Rely…).
   - Must be **neutral** — does not presuppose which alternative wins.
   - No `Decision:` prefix.
   - If the final title should state the chosen outcome but the choice is still open, preserve the outcome-shaped title with a placeholder for the unknown part (e.g. `Publish visualization information for ontologies on …`) instead of replacing it with an abstract "Choose …" title.
   - When an ADR changes from undecided to decided, update the frontmatter title and Markdown H1 so they state the chosen outcome rather than a neutral "Choose …" question.

   If the user's draft title presupposes the outcome (e.g. "Use Stripe for payments"), suggest a neutral rewrite ("Choose payment provider") and confirm before continuing.

3. **Filename.** Propose a kebab-case slug from the title (e.g. `choose-payment-provider.md`), then ask the user to accept or revise it. **Do not impose a date prefix** — naming is the user's call.

4. **Context.** Draft 2–4 context sentences from the user's stated goal, then ask the user to accept or revise them. The context must answer: what's the situation, and why is a decision needed now? Keep this scoped to the **one** decision (rule R01 — one page, one idea; cross-link other ADRs instead of inlining their detail).

5. **Selection mode.** Ask the user one question:

   > Are you picking **one** option from a set of alternatives (mutually exclusive), or selecting a **subset** (some yes, some no — e.g. a shopping list, a capability bundle)?

   - "One" → use the **tabs** template (Template B).
   - "Subset" → use the **table** template (Template C).
   - The user may answer "just one option, no real alternatives" — use the **simple** template (Template A) and skip Stages 1–2.

6. **Write an initial draft immediately.** Once the file location, title, filename, context, and selection mode are stable enough, create the ADR file with frontmatter, Context, and placeholder Decision/Consequences sections. Continue option discovery, exclusions, research, costs, and final choice by editing that file in place instead of holding the evolving ADR only in chat.

### Stage 1 — option discovery

Propose an initial list of **every** option or capability you can infer from the user's stated goal, including partial or likely-bad options. Then ask the user to accept, remove, rename, or add items.

> Here is the initial option list I see. I'll include weak and partial options too so we can narrow them down next. What should I add, remove, or rename?

Capture each as a bare label only — no Pros, no Contras, no commentary yet. The point of this stage is **breadth**: judging too early kills good options that look weak at first glance.

Keep alternatives at the right level of abstraction. An alternative must be a capable solution shape for the decision at hand, not merely a downstream tool, implementation detail, output backend, or capability that only makes sense after the main architecture is chosen. If a candidate does not solve the core problem by itself, move it to consequences, implementation steps, follow-up decisions, or reject it with that reason.

If the user gives options first, merge them with your inferred options before asking for confirmation. Do not make the user solely responsible for option discovery.

When the user says the list is complete, read it back and ask whether anything else comes to mind. Then move to Stage 2.

### Stage 2 — option exclusion

Drive the elimination — propose exclusions actively rather than surveying each option. For each option you'd reject, ask:

> I propose to exclude **[option name]** because [one-line reason]. Do you agree?

Frame as a two-option structured question: a "Yes, exclude" path plus a free-text path so the user can push back with a reason. Batch multiple obvious exclusions into one prompt when you can; don't drip-feed.

Do **not** ask "keep / drop / undecided?" for every option — that's a survey, not facilitation. Take a position on each option you can defend; let the user push back on the ones you got wrong.

If the user asks for a Socratic or directed-question method, switch from broad option dumping to one concise question at a time. Each question should expose one constraint, priority, or tradeoff needed to classify the alternatives, then use the answer to narrow or revise the ADR.

**If excluded:**
- Capture the user's accepted reason (or your proposed reason if they accepted it as-is).
- Tabs mode: becomes a `:x:` tab with the reason as its body, **and** a bullet in `### Alternatives Considered` (Context).
- Table mode: does **not** appear in the Decision table. Goes only into `### Alternatives Considered` (Context) as a bullet.

**If "keep" or "undecided", tabs mode:**
- Ask for one-line **Pro** and one-line **Contra**. (Multiple bullets are fine; one each is the floor.)
- Mark as `:question:` for now.

**If "keep" or "undecided", table mode:**
- Ask for a one-line description.
- If this is a budget decision, ask for cost (local currency and/or USD).
- Mark as `❓` for now.

After every option is processed:

- **Tabs mode**: ask "ready to pick one?" — if yes, the user names the chosen option, which becomes `:white_check_mark:`. Other kept options stay `:question:`. If no, all kept options remain `:question:` and status is **UNDECIDED**.
- **Table mode**: ask which kept rows are decided vs still undecided. Decided rows become `✅`, undecided stay `❓`.

If zero options remain kept, stop and ask the user to revisit Stage 1 — the exclusion was too aggressive.

### Stage 3 — consequences

Ask: **what changes after this decision lands?** Capture as a bullet list. If there are concrete implementation steps, render them as a task list (`- [ ]`) per rule R21.

For multi-select (table) decisions involving cost, add a budget rollup row at the bottom of the table summing USD of all `✅` rows.

### Stage 4 — finalize the file

Pick the matching template (A, B, or C below), fill it in, and write or update `<resolved-directory>/<slug>.md` using the Write tool. If an initial draft already exists from Stage 0, edit that file in place.

Resolve frontmatter `date` to today (YYYY-MM-DD) and `author` from `git config user.name` (fallback: ask the user if detection fails). No need to ask the user about either unless detection fails — these are metadata, not decisions.

**Print only the relative file path** of the new file and stop. Do not stage, do not commit, do not open an editor.

## Templates

### Template A — Simple (single decision, no real alternatives)

```markdown
---
title: <Verb-leading title>
status: draft
date: <YYYY-MM-DD, today>
author: <Author name, from `git config user.name`>
tags: [decision]
---

# <Title>

## Context

<Context paragraph(s).>

## Decision

<Single decision statement. Timeless — no current data, no temporal claims.>

## Consequences

- <Bullet>
- <Bullet>
```

### Template B — Mutually exclusive alternatives (tabs, R10)

```markdown
---
title: <Verb-leading title>
status: undecided
date: <YYYY-MM-DD, today>
author: <Author name>
tags: [decision]
hide:
  - toc
---

# <Title>

## Context

<Context paragraph(s).>

### Alternatives Considered

- <Alt 1>
- <Alt 2>
- <Alt 3>

## Decision

=== ":white_check_mark: <Chosen alternative>"

    <One-paragraph rationale.>

    <div class="grid" markdown>
    <div markdown>
    #### Pro
    - <bullet>
    </div>

    <div markdown>
    #### Contra
    - <bullet>
    </div>
    </div>

=== ":question: <Undecided alternative>"

    <Description.>

    <div class="grid" markdown>
    <div markdown>
    #### Pro
    - <bullet>
    </div>

    <div markdown>
    #### Contra
    - <bullet>
    </div>
    </div>

=== ":x: <Rejected alternative>"

    <One-line reason for rejection.>

## Consequences

- <Bullet>

#### Implementation Steps

- [ ] <Step>
- [ ] <Step>
```

**Tab ordering** (R10): chosen first, undecided in the middle, rejected last. If there's no chosen alternative yet, undecided come first, then rejected.

**Status flip when a decision lands**: change frontmatter `status: undecided` → `status: decided` and the chosen tab's icon from `:question:` to `:white_check_mark:`.

When flipping status to `decided`, also update the title and H1 to express the chosen outcome. A neutral title such as `Choose payment provider` is appropriate while open; a decided ADR should read like `Adopt Stripe for payments`.

### Template C — Multi-select subset (table, R23)

Like Template B, rejected alternatives live in `### Alternatives Considered` under Context; the Decision table shows only `✅` and `❓` rows.

Budget / shopping decisions:

```markdown
---
title: <Verb-leading title>
status: undecided
date: <YYYY-MM-DD, today>
author: <Author name>
tags: [decision]
---

# <Title>

## Context

<Context paragraph(s).>

### Alternatives Considered

- **<Rejected alt 1>.** Rejected: <one-line reason>.
- **<Rejected alt 2>.** Rejected: <one-line reason>.

## Decision

| Status | Item | Cost | $ | Description |
|--------|------|------|---|-------------|
| ✅ | [<Item>](<link>) | 2,000֏ | $5 | <description> |
| ❓ | [<Item>](<link>) |        | $25 | <description> |
| **Total** | | | **$5** | **Decided expenses** |

## Consequences

- <Bullet>
```

Non-budget multi-select (no money involved): drop the `Cost`, `$`, and `Total` columns; keep `Status | Item | Description`.

**Grouping**: for longer tables, insert bold group headers as rows with empty status/cost cells:

```markdown
|   | **Books**       |     |   | |
| ❓ | <Book 1>        |     | $30 | <desc> |
| ✅ | <Book 2>        |     | $19 | <desc> |
```

## Style rules (enforce silently while writing)

These are baked in — apply them without asking:

- **R01** — one decision per ADR. Cross-link other ADRs with absolute links instead of inlining their content.
- **R02** — one blank line before every list (otherwise MkDocs renders it inline).
- **R06** — write `⩾` and `⩽` (U+2A7E / U+2A7D), never `≥` / `≤`.
- **R08** — write `≈` for approximation, never `~` (e.g. `≈9 months`, `≈$1000`).
- **R09** — verb-leading neutral title; no `Decision:` prefix.
- **R10** — tabs only for mutually exclusive alternatives; chosen → undecided → rejected ordering; `:white_check_mark:` / `:question:` / `:x:` icons; Pro/Contra grid inside each kept tab.
- **R11** — absolute links (`/decisions/other.md`) for cross-directory references. Relative links only for files in the same directory.
- **R12** — never enumerate headings (no `## 1. Foo`, no `## A. Foo`).
- **R21** — implementation steps as task lists (`- [ ]`), not numbered lists.
- **R22** — `hide: toc` frontmatter when the ADR uses tabs (Template B). Omit it for Templates A and C.
- **R23** — table form for multi-select; Decision table shows only `✅` and `❓` rows. Rejected alternatives live in `### Alternatives Considered` under Context, never in the Decision table. Group headers as bold-text rows; budget rollup as `**Total**` row.
- **R24** — put ADR metadata such as status in frontmatter (e.g. `status: draft`, `status: undecided`, `status: decided`); do not add a visible `??? info "Metadata"` body block.
- **R25** — never add a `References` heading to ADRs. Put source links at the first relevant mention in the body, table, or decision text.
- **R26** — use Mermaid diagrams to express call relations, data flow, or software architecture when they clarify the problem. The natural home is Context (so readers see the shape before reading the alternatives), but Decision or Consequences are fine when the diagram lives downstream of the choice.
- **R27** — in Mermaid diagrams, use semantic node names (e.g. `CLIImportFiles`, `AgentTool`, `ImportHelper`), never opaque single letters like `A` / `B` / `Z`. The Mermaid source is part of the document; a reader scanning it should understand the shape without rendering it.
- **R28** — every ADR carries `date: <last-modification YYYY-MM-DD>` and `author: <name>` in frontmatter. Set `date` to today on every write (new file or edit). Resolve `author` from `git config user.name`; ask the user only if detection fails.
- **R29** — when an ADR transitions from `status: undecided` to `status: decided`, flip the title from neutral / deliberative (`Choose X`, `Decide between A and B`) to an outcome-stating verb-leading title that describes what was chosen. Update both the frontmatter `title:` and the H1 heading. The filename stays as-is unless the user asks to rename — file slugs are URLs.
- **R30** — keep the ADR scoped to its one decision. Do not drift into implementation planning (mechanism, default values, edge-case handling, file-path-laden step checklists), and do not bundle adjacent concerns into Consequences as if they were settled. When other important decisions surface during drafting, recommend a separate ADR for each rather than inlining sub-decisions; cross-link them per R01/R11.

## Constraints

- **Two stages, in order.** Never ask for Pros/Contras during option discovery (Stage 1). Discovery is breadth-only; judgment lives in Stage 2.
- **No date in filenames.** The user's naming is final — never insert `YYYY-MM-DD.` prefixes.
- **Stop after writing.** Do not run `git add`, do not run `git commit`, do not invoke `/commit`. Print the file path and exit the workflow.
- **Don't fabricate alternatives.** If the user only has one option, use Template A — don't invent rejected options to fill out tabs.
- **Never decide for the user.** When alternatives are still open, keep the ADR `status: undecided` and mark kept alternatives as undecided until the user explicitly chooses or approves the selected subset.
- **One ADR, one file.** If the user starts describing two unrelated decisions, stop and ask which one this ADR is about. The other becomes a separate `/adr` invocation.
