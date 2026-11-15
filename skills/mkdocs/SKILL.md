---
name: mkdocs
description: >-
  Required after every edit to MkDocs docs or mkdocs.yml (including a
  one-character change). Create, edit, or review MkDocs Material documentation:
  persona, concision, link presentation, admonitions, rendered behaviour, and
  macros modules. When the project has Vale configured, the review also runs
  Vale and clears error-level alerts.
---

# MkDocs Material

Required after every change under the project's MkDocs documentation tree or to
`mkdocs.yml`, including a one-character edit. Do not claim docs work done until
this skill's review has run. When the project has Vale set up (`vale ls-config`
resolves), the MkDocs review **includes** a Vale review of the changed
documentation paths—same engagement, not a separate optional pass. Do not use
this skill for a generic Markdown document that is not built with MkDocs.

## Explicit review

When the user asks `$mkdocs review` for a page or site, delegate the review to
one read-only subagent. Give it the requested scope and instruct it to read this
skill, [rules.md](rules.md), and applicable project guidance. It must apply the
reader, concision, and verification guidance below, including Vale when
configured. It must inventory named terms across the whole page, including each
item in table cells, and check their first mentions against MK11. It must not
edit project files or fix findings. Report numbered,
actionable findings with file locations and applicable rule IDs, plus Vale
warning and suggestion counts and any checks it could not complete. Report
project-guidance conflicts separately. Return its findings to the user without
making changes unless the user also requested fixes.

This read-only review mode does not change the required review and error fixes
after writing or editing documentation.

## Reader and concision

- Before writing or reviewing, read `docs/AGENTS.md` when present and use its
  reader persona, scope, and review guidance. If it leaves a material audience
  decision unresolved, ask the user; otherwise infer the audience from the
  task.
- Run the `/concise` skill when reviewing a documentation page or site. Apply its
  semantic-repetition and tautology checks to prose, examples, and adjacent
  commands.
- Review reader progression across consecutive sections within a page and
  consecutive pages within a navigation group. Where order, links,
  prerequisites, or wording suggest a sequence, check that each next part
  continues, applies, deepens, contrasts with, or depends on what came before.
  Flag abrupt jumps or missing prerequisites. Treat navigation as evidence,
  not proof: indexes and reference collections may group independent pages, so
  do not force a linear relationship.
- Do not retain empty or noisy prose. Each sentence must give the documented
  reader an action, prerequisite, rationale, scope, or consequence that is not
  already evident from adjacent content. Flag redundant prose in review.
- Number each review finding so the user can refer to it individually.
- Report each conflict with project-local guidance as a separate finding, even when the same example has other issues.

## Shared rules

Read and apply [rules.md](rules.md) when writing or reviewing MkDocs pages.
Give the same rules to any writer and reviewer roles.

## Verification

- For raw HTML attributes, Markdown extensions, tables, tooltip titles, or
  custom CSS classes, verify the rendered result in Chromium via Playwright.
- Follow the documented reader journey through links and controls. For content
  revealed by tabs or other controls, verify both interaction and direct
  fragment URLs that promise to reveal it.
- When documentation uses mutable external data, build and review it using
  saved captures. Keep retrieval and rewriting of examples in explicit refresh
  operations; inspect verification commands for those effects before running
  them.
- Before starting a development server, inspect project dev tooling for its
  documented local URL and probe it. Reuse a responsive server; do not infer
  its absence from a partial port scan.
- Keep agent-guidance files excluded through `exclude_docs` in `mkdocs.yml`.
- **Vale (required when configured).** If `vale ls-config` resolves, treat
  Vale as part of this review: run it on the changed documentation paths
  (and other prose the project’s Vale config covers, such as `README.md`, when
  those files changed). Follow the project’s `vale-fix` skill when present;
  otherwise fix **error**-level alerts yourself before claiming the review
  done. Report warning and suggestion counts; they do not block the review
  unless the project says otherwise.
- If Vale is not configured, do not install it unprompted. When the review
  itself finds a prose defect a style linter would have caught mechanically
  (misspelling of a product term, banned wording, heading casing the project
  cares about, and similar), fix the immediate issue, then briefly propose
  setting up Vale and the `vale-*` skills so the same class of defect fails
  deterministically next time. One offer per engagement is enough; do not
  nag on every edit.
