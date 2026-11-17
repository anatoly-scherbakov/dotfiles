# MkDocs Rules

These rules are mandatory for both writing and reviewing MkDocs pages.

**MK01**: Show the right-hand table of contents only when it has three or more entries.
For fewer entries, set `hide: [toc]` in the page frontmatter. Count the
rendered TOC items (Material heading levels that appear in the sidebar), not
only the headings written in the Markdown source.

**MK02**: One page stands for one idea. Keep a page whole while it has one idea. When a
second independent idea arrives, give each idea its own page and make the
parent an index. Adding an idea must not rewrite the page for an existing idea.

**MK03**: Give runnable examples the execution context they require: prerequisites,
filenames, working directory, complete flags, and whether a command keeps
running or needs a second terminal. Distinguish user-created inputs from
generated outputs; output directory previews show generated files only.

**MK04**: Never hand-write a generated document into a page. Include the file the
command wrote, through the project's renderer.

**MK05**: A command and its result are read as one step. Put the result immediately
after the command. Prose or another command between them breaks the flow.

**MK06**: Keep front-page examples self-contained. For a short shell query accepted on
standard input, use the project's selected inline form (for example,
`echo '…' | command --query -`) instead of requiring a separate file.

**MK07**: Format a link to a GitHub repository root as
`[:fontawesome-brands-github: \`org/repo\`](https://github.com/org/repo)`.
Keep the repository identity inside the link even when surrounding prose
supplies a human-friendly product name.

**MK08**: Format a GitHub file link as
`[:fontawesome-brands-github: \`filename.ext\`](https://github.com/org/repo/blob/ref/path/filename.ext)`.
The filename, rather than the repository, identifies the linked resource.

**MK09**: Use MkDocs Material icon shortcodes instead of raw emoji when an icon is
intended to match the site theme.

**MK10**: Give every Material navigation section index an `icon:` frontmatter entry
that matches its H1 shortcode; an H1 shortcode alone does not appear in the
sidebar.

**MK11**: Link the first rendered mention of each named term or brand to a relevant
source. For a named product, vendor, programming language or data format, check
the theme's `simple/` and `fontawesome/brands/` icon packs and include its icon
when available. Use a generic Material icon only when no brand SVG exists.

**MK12**: When a project documents RO-Crates, make the first rendered `RO-Crate`
mention a link to [RO-Crate](https://www.researchobject.org/ro-crate/).

**MK13**: Format a card index from [templates/cards.md](templates/cards.md). Keep an
existing project's heading icons consistent; do not introduce site-wide icon
or divider rules merely from this skill.

**MK14**: Document a Rust CLI from [templates/rust-cli.md](templates/rust-cli.md).
Derive the argument tables and the command index from the compiled command.

**MK15**: Use the Single Responsibility Principle (SRP) to decide where a fact
belongs across code, configuration, metadata, and documentation. Prefer
the text that was never written over a redundant restatement. If readers
need a repeated value, render it from its canonical source to prevent
drift.

**MK16**: Avoid copying repeated content blocks between pages. Include canonical files
where appropriate; when `mkdocs-macros-plugin` is already configured,
define and reuse a macro.

**MK17**: When project-local MkDocs macros outgrow one module, suggest a package named
for the configured `module_name` (for example, `docs_macros/`). Group
implementations by responsibility and keep `__init__.py` limited to explicit
reexports, including `define_env`. Preserve the configured entry point and
existing imports when converting.

**MK18**: Render CSV example data from its canonical file through the project's
configured renderer.

**MK19**: When files are part of the lesson, pair readable previews with links to the
complete, exact artifacts. Preserve meaningful identifiers and empty cells.
Choose result previews from the actual media type when available, which can
differ from the filename extension or requested format.

**MK20**: Show discontiguous ranges from one source file in a single fenced block,
using line-range includes and ellipses or comments for omitted sections.

**MK21**: Use an admonition when a page needs a compact, reader-facing status or scope
notice. Give it a precise title and avoid repeating the following paragraph.

**MK22**: Treat a page's metadata as belonging to that page type. Do not apply an ADR
metadata macro to a supporting planning page merely because it sits beneath
an ADR.

**MK24**: In tables and diagrams, prefer relevant icons over yes/no text.
Distinguish unknown from no, and provide accessible labels.

**MK25**: Use existing admonition styling when it meets the need. Add custom
CSS only when a distinct appearance is required.

**MK26**: Right-align quote sources. Use `⇐` for “derived from” & `⇒`
for the inverse relationship.

**MK27**: Prefer `&` to “and” in prose & table labels. In tables, consider
a line break between items instead when it makes the table narrower.

**MK28**: Link to the most specific relevant source, such as a section heading
or source lines, when a stable target directly supports the linked claim.

**MK29**: Give table row-group headings a distinct background so readers can
recognize the groups in every supported color scheme.
