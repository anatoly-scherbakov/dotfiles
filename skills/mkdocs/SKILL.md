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

- Show the right-hand table of contents only when it has three or more entries.
  For fewer entries, set `hide: [toc]` in the page frontmatter. Count the
  rendered TOC items (Material heading levels that appear in the sidebar), not
  only the headings written in the Markdown source.
- One page stands for one idea. Keep a page whole while it has one idea. When a
  second independent idea arrives, give each idea its own page and make the
  parent an index. Adding an idea must not rewrite the page for an existing idea.
- Give runnable examples the execution context they require: prerequisites,
  filenames, working directory, complete flags, and whether a command keeps
  running or needs a second terminal. Distinguish user-created inputs from
  generated outputs; output directory previews show generated files only.
- Never hand-write a generated document into a page. Include the file the
  command wrote, through the project's renderer.
- A command and its result are read as one step. Put the result immediately
  after the command. Prose or another command between them breaks the flow.
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
- Give every Material navigation section index an `icon:` frontmatter entry
  that matches its H1 shortcode; an H1 shortcode alone does not appear in the
  sidebar.
- For a named product or vendor, check the theme's `simple/` and
  `fontawesome/brands/` icon packs first and use that brand shortcode when
  present. Use a generic Material icon only when no brand SVG exists.
- When a project documents RO-Crates, make the first rendered `RO-Crate`
  mention a link to [RO-Crate](https://www.researchobject.org/ro-crate/).
- Format a card index from [templates/cards.md](templates/cards.md). Keep an
  existing project's heading icons consistent; do not introduce site-wide icon
  or divider rules merely from this skill.
- Document a Rust CLI from [templates/rust-cli.md](templates/rust-cli.md).
  Derive the argument tables and the command index from the compiled command.
- Avoid copying repeated content blocks between pages. Include canonical files
  where appropriate; when `mkdocs-macros-plugin` is already configured,
  define and reuse a macro.
- When project-local MkDocs macros outgrow one module, suggest a package named
  for the configured `module_name` (for example, `docs_macros/`). Group
  implementations by responsibility and keep `__init__.py` limited to explicit
  reexports, including `define_env`. Preserve the configured entry point and
  existing imports when converting.
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
