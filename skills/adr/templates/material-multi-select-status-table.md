{# template: material-multi-select-status-table

When to use: adopt a subset — shopping list or capability bundle.

Frontmatter: include hide: [toc] (MkDocs Material).

Rejected alternatives: optional Context subsection (any heading; bullets or table). Rejected options do not appear as rows in the Decision table.

Decision table: only ✅ (decided) and ❓ (undecided) rows — no rejected rows.

For cost decisions: add a **Total** row summing USD of all ✅ rows at the bottom of the Decision table.

Group headers: for longer status tables, insert bold group headers as rows with empty status/cost cells, e.g.:

|   | **Books** |     |   | |
| ❓ | <Book 1>  |     | $30 | <desc> |
| ✅ | <Book 2>  |     | $19 | <desc> |

Non-budget decisions: drop Cost, $, and Total columns; keep Status | Item | Description.

Stage 2 — if excluded: Context subsection only; not in the Decision table.

Stage 2 — if keep or undecided: ask for a one-line description; if this is a budget decision, ask for cost (local currency and/or USD); mark ❓.

Stage 2 — after all options: ask which kept rows are decided vs still undecided; decided → ✅, undecided → ❓. Never decide for the user.

Stage 3 — for cost decisions, add the budget **Total** row summing USD of all ✅ rows.
#}
---
title: <Verb-leading title>
status: undecided
date: <YYYY-MM-DD, today>
author: <Author name>
tags: [decision]
hide: [toc]
---

# <Title>

## :material-text-box-outline: Context

<Context paragraph(s).>

### <Optional rejected-alternatives heading>

- **<Rejected alt 1>.** Rejected: <one-line reason>.
- **<Rejected alt 2>.** Rejected: <one-line reason>.

## :material-arrow-decision-outline: Decision

| Status | Item | Cost | $ | Description |
|--------|------|------|---|-------------|
| ✅ | [<Item>](<link>) | 2,000֏ | $5 | <description> |
| ❓ | [<Item>](<link>) |        | $25 | <description> |
| **Total** | | | **$5** | **Decided expenses** |

## :material-arrow-right-bold-outline: Consequences

- <Bullet>

#### Implementation Steps

- [ ] <Step>
- [ ] <Step>
