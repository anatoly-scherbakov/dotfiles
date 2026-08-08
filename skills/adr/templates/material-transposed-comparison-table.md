{# template: material-transposed-comparison-table

When to use: compare alternatives across many criteria — libraries, features, backends.

Frontmatter: include hide: [toc] (MkDocs Material).

Rejected alternatives: optional Context subsection for prerequisite rejections that never entered the matrix (any heading; bullets or table). Rejected finalists may remain as comparison rows or columns when side-by-side evidence supports the exclusion; record the outcome in the Decision cell.

Orientation: choose the orientation that minimizes horizontal scrolling at the
expected documentation viewport. Compare the expected total width of the two
shapes using the actual alternative labels, criterion labels, and compact cell
content; do not use a fixed alternative-count threshold. Put alternatives in
rows when the criterion columns are narrower than one column per alternative.
Put alternatives in columns when the alternative columns are narrower than one
column per criterion. Verify the rendered choice at a normal desktop viewport;
the native horizontal scroll wrapper remains a fallback for narrow screens.

Ordering: place every non-excluded alternative first and keep all excluded
alternatives together at the bottom or right edge of the matrix. Preserve the
existing relative order within the non-excluded and excluded groups unless the
user requests another ordering. When an alternative becomes excluded, move its
entire row or column—including its label, every criterion cell, and Decision
cell—into the trailing excluded group.

Outcome marking (Stage 2 — after a choice is made):
- Add `class="chosen"` to every header and data cell in the selected
  alternative's row or column. Ensure the registered stylesheet gives `.chosen` a
  light-green tint in both color schemes. Recommended colors: `#edf7ed` in
  light mode and `#17291e` in dark mode. When a Decision column is present,
  record `:white_check_mark: Chosen` in its cell.
- A finalist that satisfies the decision's constraints but loses to the chosen
  alternative is **not selected**, not excluded. Add `class="not-selected"`
  to every header and data cell in that alternative's row or column.
- Ensure a stylesheet registered through `extra_css` gives `.not-selected` a
  light-yellow tint in both light and dark color schemes. Recommended colors:
  `#fff8e1` in light mode and `#332b16` in dark mode.
- When a Decision column is present, record
  `:material-minus-circle-outline: Not selected` in its cell.
- Reserve the red `.excl` and `.excl.hot` styles, the `:x:` icon, and an
  exclusion reason for alternatives rejected on evidence or a hard constraint.

Exclusion marking (Stage 2 — if excluded):
- Add `data-adr-comparison` to the matrix `<table>`. Do not add a class to the
  table: MkDocs Material applies its native table layout to classless tables.
- Add `class="excl"` to every header and data cell in an excluded alternative's
  row or column. Add `hot` to each disqualifying evidence cell, for example
  `class="excl hot"`.
- Ensure a stylesheet registered through `extra_css` gives `.excl` a light-red
  tint and `.excl.hot` a stronger red in both light and dark color schemes.
  Match the HTML template's colors: `#fdf0ee` / `#f7d4cd` in light mode and
  `#261a19` / `#45231e` in dark mode.
- Keep the table classless so MkDocs Material generates its native
  `.md-typeset__scrollwrap`; verify that wrapper scrolls horizontally on narrow
  viewports without document-level overflow.
- When a Decision column is present, keep it in the tinted row or column and
  record `:x: Excluded` with a concise reason.

The matrix in ## Decision is the primary decision surface. Use group rows or
columns when they improve scanning. Include one Decision cell per alternative
while outcomes remain open. Once every outcome is settled, the Decision column
may be omitted if every alternative row or column carries its outcome class
(`chosen`, `not-selected`, or `excl`) and a visible legend defines those
background colours; the ADR title and frontmatter status then record the
selected outcome.
Link every alternative label to its primary documentation or repository when
one exists. Use the R36 GitHub-link form for repository links.

Criterion granularity: give every independently decisive requirement its own
criterion row or column. Do not hide a requirement inside an umbrella capability or a
combined-stack assessment when it can independently keep or exclude an
alternative.

Every icon-only status cell must have a concise `title` tooltip that explains
the reason for its status. Where that reason is factual, make the icon a link
to its primary source per R35. Never use an unexplained status icon. Add a
visible legend when :warning: or other non-obvious markers appear.

Dense evidence matrices: use linked status icons with concise `title` tooltips
when a criterion is categorical. Keep a visible legend because the tooltip is
supplemental and is not reliably discoverable on touch devices.
Link compact visible values such as versions instead of repeating explanatory
sentences. Preserve exclusion reasons in the Decision row or concise notes
below the matrix. Follow R36 when the evidence URL is a GitHub repository.

Stage 2 — if excluded: may remain a comparison row or column with criterion cells and an exclusion outcome in its Decision cell; use Context for prerequisite rejections that never entered the matrix.

Stage 2 — if keep or undecided: add as a comparison row or column; gather criterion cells with source links per R35; record one outcome per alternative.

Stage 2 — after all options: ask which alternatives have a decided outcome vs still undecided; record each outcome in its Decision cell; overall status stays undecided until the user closes all open alternatives. Never decide for the user.
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

<table data-adr-comparison markdown="1">
  <tr markdown="span">
    <th>Alternative</th>
    <th><Criterion></th>
    <th><Criterion with prose claim></th>
    <th>Decision</th>
  </tr>
  <tr markdown="span">
    <th class="chosen">[:fontawesome-brands-github: `org/repo`](https://github.com/org/repo)</th>
    <td class="chosen">[:white_check_mark:](<source URL> "<short evidence tooltip>")</td>
    <td class="chosen">[<claim>](<source URL>)</td>
    <td class="chosen">:white_check_mark: Chosen</td>
  </tr>
  <tr markdown="span">
    <th class="not-selected">[:fontawesome-brands-github: `org/repo`](https://github.com/org/repo)</th>
    <td class="not-selected">[:white_check_mark:](<source URL> "<short evidence tooltip>")</td>
    <td class="not-selected">[<claim>](<source URL>)</td>
    <td class="not-selected">:material-minus-circle-outline: Not selected</td>
  </tr>
  <tr markdown="span">
    <th class="excl">[:fontawesome-brands-github: `org/repo`](https://github.com/org/repo)</th>
    <td class="excl hot">[:x:](<source URL> "<disqualifying evidence tooltip>")</td>
    <td class="excl">[<claim>](<source URL>)</td>
    <td class="excl">:x: Excluded — <concise reason></td>
  </tr>
</table>

<Legend footnote — e.g. what :warning: means, with [source links](<URL>) for any factual claims.>

## :material-arrow-right-bold-outline: Consequences

- <Bullet>

#### Implementation Steps

- [ ] <Step>
- [ ] <Step>
