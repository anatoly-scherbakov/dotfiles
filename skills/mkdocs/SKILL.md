---
name: mkdocs
description: Create, edit, or review MkDocs Material documentation, especially link presentation, admonitions, and rendered behaviour.
disable-model-invocation: true
---

# MkDocs Material

Use for MkDocs Material pages or configuration where Markdown source alone is
insufficient to verify the reader-facing result. Do not use it for a generic
Markdown document that is not built with MkDocs.

## Authoring

- Format a link to a GitHub repository root as
  `[:fontawesome-brands-github: \`org/repo\`](https://github.com/org/repo)`.
  Keep the repository identity inside the link even when surrounding prose
  supplies a human-friendly product name.
- Format a GitHub file link as
  `[:fontawesome-brands-github: \`filename.ext\`](https://github.com/org/repo/blob/ref/path/filename.ext)`.
  The filename, rather than the repository, identifies the linked resource.
- Use MkDocs Material icon shortcodes instead of raw emoji when an icon is
  intended to match the site theme.
- Use an admonition when a page needs a compact, reader-facing status or scope
  notice. Give it a precise title and avoid repeating the following paragraph.
- Treat a page's metadata as belonging to that page type. Do not apply an ADR
  metadata macro to a supporting planning page merely because it sits beneath
  an ADR.

## Verification

- For raw HTML attributes, Markdown extensions, tables, tooltip titles, or
  custom CSS classes, verify the rendered result in Chromium via Playwright.
- Before starting a development server, reuse the documented local development
  URL when it is already responsive.
- Keep agent-guidance files excluded through `exclude_docs` in `mkdocs.yml`.
