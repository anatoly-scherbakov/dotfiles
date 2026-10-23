---
name: concise
description: >-
  Detect semantic repetition across documents (specs, examples, prose, data
  graphs) and propose ways to reduce it. Use when the user invokes /concise,
  asks to find duplicate or overlapping content, reduce repetition, or DRY
  up documentation/examples.
---

# Concise

Finds semantic repetition across documents, proposes remediation options, drives decisions via structured questions, and produces an action plan. Implementation is optional and runs only if the user approves at the end.

## When to use

- The user types `/concise`.
- The user asks to find duplicate, overlapping, or redundant content.
- The user wants to DRY up documentation, examples, or data graphs.
- A prior conversation already identified repetition and the user wants a plan to address it.

Do **not** invoke for unrelated editing, refactoring without repetition, or general proofreading.

## Overlap types

Distinguish these before recommending action:

| Type | What it is | Reduction candidate? |
|------|------------|----------------------|
| **Lexical** | Same or near-identical text | Yes, if unintentional |
| **Structural** | Same outline or section pattern | Yes, if unintentional |
| **Semantic** | Same facts/meaning in different surface form | Yes |
| **Tautology** | Same fact twice with no new information (often in one phrase) | Yes — always ban |
| **Pedagogical** | Intentional reuse for teaching (minimal → richer) | Flag only — never auto-delete |

**Semantic** and **structural** overlaps are candidates for reduction by default. **Tautologies** are never kept. **Pedagogical** overlaps must be flagged "possibly intentional" and confirmed with the user.

Tautology example: `pyld.jsonld.expand() via digitalbazaar/pyld` → write `pyld.jsonld.expand()`.

For case studies and pattern catalog, see [examples.md](examples.md).

## Workflow

### Stage 0 — Scope

1. Resolve the corpus:
   - User-named files, `@`-references, directories, or conversation context.
   - If the user already named specific files, use those — do not re-ask scope.
2. When scope is ambiguous, ask **one** structured question:
   - Scan only named files
   - Scan a directory (user names it)
   - Scan the whole project
3. Record document roles when visible (e.g. "intro example" vs "canonicalization example" from spec section headings or file paths).

### Stage 1 — Scan

Read all in-scope documents. Build **clusters** (groups of 2+ documents sharing content), not just pairwise duplicates.

Detection by format:

- **Data / graphs** (YAML-LD, JSON-LD, JSON, YAML): compare expanded semantics — same subject, type, properties/triples; shared `@context` terms.
- **Prose** (Markdown, HTML spec): same claims, definitions, or worked examples.
- **Code**: same algorithm or domain modeled with cosmetic differences.
- **Cross-format**: equivalence across formats is expected when one is derived from another (e.g. `basic.jsonld` ↔ `basic.yamlld`). Flag only when a *third* artifact repeats the same graph unnecessarily.

### Stage 2 — Report

Present a findings table:

| # | Cluster | Overlap type | Shared content (summary) | Possibly intentional? | Files |
|---|---------|--------------|--------------------------|----------------------|-------|

For each cluster, cite **specific** shared elements (e.g. subject `dbr:Proxima_Centauri_b`, `dbo:Planet`, `dbp:star` edge) — not vague "they're similar".

If no clusters found, say so and stop.

### Stage 3 — Propose remediation

For each cluster, recommend one action from the menu below with a one-line rationale. Respect document roles (e.g. minimal example paired with JSON-LD comparison → prefer **differentiate** or **trim**, not blind **merge**).

| Action | When to recommend |
|--------|-------------------|
| **Keep** | Intentional pedagogical layering; document the relationship |
| **Differentiate** | Examples should teach distinct concepts |
| **Extract shared base** | One canonical artifact; others reference it |
| **Merge** | Documents serve the same role; one suffices |
| **Trim** | Superset copy repeats a minimal core unnecessarily |
| **Defer** | Real overlap but out of scope for this session |

### Stage 4 — Structured questions

Use `AskQuestion` when available; otherwise plain-text numbered choices.

**Round 1 — Cluster selection** (multi-select): which findings to address in this session?

**Round 2 — Per selected cluster** (single-select): which remediation action?

Options: the six actions above. For pedagogical overlaps, include **Keep as intentional layering** explicitly. Include a free-text escape: "Other — I'll explain".

Skipped clusters are excluded from the action plan.

### Stage 5 — Action plan

Emit a consolidated markdown plan:

```markdown
# Concise remediation plan

## Summary
[One paragraph: scope, clusters addressed, clusters deferred/skipped]

## Decisions

### Cluster N: [short label]
- **Action:** [chosen action]
- **Rationale:** [why]
- **Files to touch:** [list]
- **Downstream updates:** [generated artifacts, diagrams, spec data-include, scripts, tests]
- **Verification:** [project-specific commands, e.g. make spec]

## Implementation order
1. ...
2. ...

## Deferred / skipped
- ...
```

**Stop here by default.** Then ask one final structured question:

> Implement approved changes now?

- **Yes** → execute only approved clusters; run verification commands from the plan; do not touch deferred/skipped items.
- **No** → print the plan inline (or write to a user-specified path if they asked); exit the workflow.

## Implementation rules (when user approves)

- Change only files tied to approved clusters.
- Update downstream artifacts referenced by the plan (generated JSON, mermaid, spec includes, generator scripts).
- Run project verification commands listed in the plan before claiming success.
- Do **not** run `git add` or `git commit` unless the user separately asks.

## Constraints

- Never delete or merge without explicit user approval per cluster.
- Never treat pedagogical overlap as a bug without asking.
- Never allow tautologies — same fact twice with no new information.
- Do not auto-commit — user invokes `/commit` separately if desired.
- Do not fabricate overlap — if documents are distinct, report "no clusters found".
- Prefer minimal diffs; match existing project conventions.
