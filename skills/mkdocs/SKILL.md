---
name: mkdocs
description: Create, edit, or review MkDocs Material documentation, especially link presentation, admonitions, and rendered behaviour.
disable-model-invocation: true
---

# MkDocs Material

Use for MkDocs Material pages or configuration where Markdown source alone is
insufficient to verify the reader-facing result. Do not use it for a generic
Markdown document that is not built with MkDocs.

## Reader and concision

- Before writing or reviewing, read `docs/AGENTS.md` when present and use its
  reader persona, scope, and review guidance. If it leaves a material audience
  decision unresolved, ask the user; otherwise infer the audience from the
  task.
- Run the `/concise` skill when reviewing a documentation site. Apply its
  semantic-repetition and tautology checks to prose, examples, and adjacent
  commands.
- Do not retain empty or noisy prose. Each sentence must give the documented
  reader an action, prerequisite, rationale, scope, or consequence that is not
  already evident from adjacent content. Flag redundant prose in review.

## Authoring

- Give runnable examples the execution context they require: prerequisites,
  filenames, working directory, complete flags, and whether a command keeps
  running or needs a second terminal. Distinguish user-created inputs from
  generated outputs; output directory previews show generated files only.
- Keep front-page examples self-contained. For a short shell query accepted on
  standard input, use the project's selected inline form (for example,
  `echo '…' | command --query -`) instead of requiring a separate file.
- Format a link to a GitHub repository root as
  `[:fontawesome-brands-github: \`org/repo\`](https://github.com/org/repo)`.
  Keep the repository identity inside the link even when surrounding prose
  supplies a human-friendly product name.
- Format a GitHub file link as
  `[:fontawesome-brands-github: \`filename.ext\`](https://github.com/org/repo/blob/ref/path/filename.ext)`.
  The filename, rather than the repository, identifies the linked resource.
- Use MkDocs Material icon shortcodes instead of raw emoji when an icon is
  intended to match the site theme.
- When a project documents RO-Crates, make the first rendered `RO-Crate`
  mention a link to [RO-Crate](https://www.researchobject.org/ro-crate/).
- When a project already uses heading icons or Material cards, keep their
  conventions consistent; do not introduce site-wide icon or divider rules
  merely from this skill.
- Avoid copying repeated content blocks between pages. Include canonical files
  where appropriate; when `mkdocs-macros-plugin` is already configured,
  define and reuse a macro.
- Render CSV example data from its canonical file through the project's
  configured renderer.
- When files are part of the lesson, pair readable previews with links to the
  complete, exact artifacts. Preserve meaningful identifiers and empty cells.
  Choose result previews from the actual media type when available, which can
  differ from the filename extension or requested format.
- Show discontiguous ranges from one source file in a single fenced block,
  using line-range includes and ellipses or comments for omitted sections.
- Use an admonition when a page needs a compact, reader-facing status or scope
  notice. Give it a precise title and avoid repeating the following paragraph.
- Treat a page's metadata as belonging to that page type. Do not apply an ADR
  metadata macro to a supporting planning page merely because it sits beneath
  an ADR.

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
