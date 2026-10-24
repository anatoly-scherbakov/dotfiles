---
name: shower
description: Create, edit, and verify offline Shower HTML presentations using the user's Ribbon design, j build workflow, and linked-data example conventions.
disable-model-invocation: true
---

# Shower presentations

Use for local Shower HTML decks. Preserve an existing deck's build and design.
For a new deck, use the Ribbon theme and the workflow below. The local reference
is `~/projects/streaming-demo`; inspect its agent guidance and relevant sources
before borrowing assets or conventions. Retain vendored licenses and provenance.

## Source and build

- Keep editable markup in `templates/index.html.jinja`, styling in
  `slides/styles.css`, canonical inputs in `examples/`, and generated output in
  `slides/index.html`, following the existing project's layout when it differs.
- Provide an executable `./j` build entry point and `make render` / `make serve`.
  Use Jinja2 for markup and add a Node renderer only when highlighting or other
  existing build steps need it. Document dependencies, the local URL, and which
  files to edit. Run the build after edits.
- Embed example files through the build instead of maintaining a second copy
  inside slide markup. Generate equivalent serializations from one canonical
  source. Keep fields, identifiers, units, and timestamps consistent. Derive
  and label variants that change the example's meaning.
- Keep Shower, fonts, syntax highlighting, and any Mermaid runtime local so the
  deck works offline. Preserve the reference theme's 16:9 layout, typography,
  and navigation unless the user requests another design.
- Put speaker notes in each slide's hidden `aside`. If separate notes are
  useful, generate them from those same elements. Match notes and timing to
  the actual talk.

## Examples and sources

- Always use YAML-LD for linked-data examples. Use an explicit `@context` and
  appropriate identifier coercion or `@id` objects so resources stay resources.
  A request specifically to compare serializations may show the formats being
  compared, with YAML-LD as the linked-data example's canonical representation.
- Parse YAML and validate linked-data syntax through PyLD expansion. When
  converting a prior example, compare its RDF meaning as well. Check vocabulary
  applicability separately from expansion and run executable snippets in the
  actual processor shown. Clearly label hypothetical APIs and proposed behavior.
- Keep code highlighted and meaningful output comments visible. Split dense
  examples across slides rather than shrinking them to fit.
- Put source and implementation references at the bottom right, outside titles.
  For an implementation, include its specification beside it when applicable.
- Display GitHub repository links with the GitHub icon and exact `owner/repo`.
  Link PRs and issues using their full URLs and follow the user's global rules
  for visible references. Audit references throughout the deck when changing
  their convention.
- Use Mermaid for diagrams and retain editable `.mmd` sources. Point dependency
  arrows from the base to the dependent item and distinguish kinds of dependency.

## Rendered verification

- Inspect the documented server command and URL before starting another server.
  Rebuild and reload the current output before checking it.
- Validate in Chromium through Playwright MCP only. Inspect every slide at full
  size, including code, source placement, fonts, and overflow. Exercise forward
  and backward navigation, overview mode, and direct slide fragment URLs.
- Wait for fonts and diagrams to finish before judging layout. Verify offline
  assets and meaningful examples as well as the slide markup.
- If Playwright MCP cannot connect, preserve the built deck and report visual
  verification as blocked. Do not launch another browser or substitute HTTP or
  source inspection for the required rendered check.
- Cut repeated claims and captions that only narrate the example. Keep the
  requested slide count and frame open ideas as proposals.
