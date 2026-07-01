{# template: material-transposed-comparison-table

When to use: compare alternatives across many criteria — libraries, features, backends.

Frontmatter: include hide: [toc] (MkDocs Material).

Rejected alternatives: optional Context subsection for prerequisite rejections that never entered the matrix (any heading; bullets or table). Rejected finalists may remain as comparison columns when side-by-side evidence supports the exclusion; record the outcome in the Decision row.

The transposed matrix in ## Decision is the primary decision surface: alternatives as columns, criteria as rows. Use group rows when they improve scanning. Include a Decision row at the bottom with per-column outcomes.

Icon-only cells need no source link; prose cells must cite sources per R35. Add a legend footnote when :warning: or other non-obvious markers appear.

Stage 2 — if excluded: may remain a comparison column with criterion rows and an exclusion outcome in the Decision row; use Context for prerequisite rejections that never entered the matrix.

Stage 2 — if keep or undecided: add as a comparison column; gather criterion rows with source links per R35; record per-column outcome in the Decision row.

Stage 2 — after all options: ask which columns have a decided outcome vs still undecided; record in the Decision row; overall status stays undecided until the user closes all open columns. Never decide for the user.
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

| Criterion | <Alt 1> | <Alt 2> |
|-----------|:-------:|:-------:|
| <criterion> | :x: | :white_check_mark: |

<One-line summary of why rejected alternatives were excluded.>

## :material-arrow-decision-outline: Decision

<table markdown="1">
  <tr markdown="span">
    <th></th>
    <th>[:fontawesome-brands-github: `org/repo`](https://github.com/org/repo)</th>
    <th>[:fontawesome-brands-github: `org/repo`](https://github.com/org/repo)</th>
  </tr>
  <tr markdown="span">
    <th colspan="3"><Group label></th>
  </tr>
  <tr markdown="span">
    <th><Criterion></th>
    <td>:white_check_mark:</td>
    <td>:x:</td>
  </tr>
  <tr markdown="span">
    <th><Criterion with prose claim></th>
    <td>[<claim>](<source URL>)</td>
    <td>[<claim>](<source URL>)</td>
  </tr>
  <tr markdown="span">
    <th>Decision</th>
    <td><Outcome for this alternative></td>
    <td><Outcome for this alternative></td>
  </tr>
</table>

<Legend footnote — e.g. what :warning: means, with [source links](<URL>) for any factual claims.>

## :material-arrow-right-bold-outline: Consequences

- <Bullet>

#### Implementation Steps

- [ ] <Step>
- [ ] <Step>
