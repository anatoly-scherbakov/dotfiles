# ADR Rules

These rules are mandatory for both the writer and reviewer roles.

Template shape and usage live only in `templates/<name>.md` (`{# ... #}` header comment); [templates/README.md](templates/README.md) is the catalog. Validate against the chosen template file — not against `rules.md` or any other skill file.

- **R01** — one decision per ADR. Cross-link other ADRs with absolute links instead of inlining their content.
- **R02** — one blank line before every list (otherwise MkDocs renders it inline).
- **R06** — write `⩾` and `⩽` (U+2A7E / U+2A7D), never `≥` / `≤`.
- **R08** — write `≈` for approximation, never `~` (e.g. `≈9 months`, `≈$1000`).
- **R09** — verb-leading **outcome-shaped** title that states the raw decision, not the activity of writing the ADR. No `Decision:` prefix. Do **not** use meta titles like `Choose …`, `Decide between …`, or `Pick a …` — those describe facilitation, one level above the decision. Undecided and decided titles share the same sentence shape; only the unknown slot differs (see R29).
- **R11** — absolute links (`/decisions/other.md`) for cross-directory references. Relative links only for files in the same directory.
- **R12** — never enumerate headings (no `## 1. Foo`, no `## A. Foo`).
- **R21** — implementation steps as task lists (`- [ ]`), not numbered lists.
- **R24** — put ADR metadata such as status in frontmatter (e.g. `status: draft`, `status: undecided`, `status: decided`); do not add a visible `??? info "Metadata"` body block.
- **R25** — never add a `References` heading to ADRs. Put source links at the first relevant mention in the body, table, or decision text.
- **R26** — use Mermaid diagrams to express call relations, data flow, or software architecture when they clarify the problem. The natural home is Context (so readers see the shape before reading the alternatives), but Decision or Consequences are fine when the diagram lives downstream of the choice.
- **R27** — in Mermaid diagrams, give nodes **semantic IDs** (e.g. `CLIImportFiles`, `AgentTool`), never opaque single letters like `A` / `B` / `Z`. IDs are for the graph source, not for readers. Every rendered node **must** also have a **human-readable display label** in quotes/brackets (e.g. `CLIImportFiles["CLI import files"]`). Never leave CamelCase/PascalCase as the visible title.
- **R28** — every ADR carries `date: <last-modification YYYY-MM-DD>` and `author: <name>` in frontmatter. Set `date` to today on every write (new file or edit). Resolve `author` from `git config user.name`; ask the user only if detection fails.
- **R29** — title/H1 encode the decision outcome, with Unicode ellipsis `…` (U+2026) as a placeholder for unknown slot(s) while undecided:
  - **`status: undecided`** — frontmatter `title:` and H1 **must** contain `…` in place of the unknown part(s). Example: `Implement YAML-LD support in …` (not `Choose a language for YAML-LD`).
  - **`status: decided`** — frontmatter `title:` and H1 **must not** contain `…`; fill in the factual outcome. Example: `Implement YAML-LD support in Rust`.
  - Update both frontmatter `title:` and the Markdown H1 together whenever status or the chosen outcome changes.
  - The filename stays as-is unless the user asks to rename — file slugs are URLs.
- **R30** — keep the ADR scoped to its one decision. Do not drift into implementation planning (mechanism, default values, edge-case handling, file-path-laden step checklists), and do not bundle adjacent concerns into Consequences as if they were settled. When other important decisions surface during drafting, recommend a separate ADR for each rather than inlining sub-decisions; cross-link them per R01/R11.
- **R31** — when the user asks to quote a source, quote the requested source text directly and link it at the quote; do not replace requested exact wording with paraphrase or a partial quote plus summary.
- **R32** — before using non-obvious MkDocs, Markdown extension, or raw HTML attributes in an ADR, read the relevant documentation and verify the rendered behavior instead of guessing from memory.
- **R34** — prefer MkDocs icon shortcodes such as `:white_check_mark:`, `:question:`, `:x:`, and `:warning:` over raw emoji in ADR content, especially tables.
- **R35** — factual claims about alternatives (features, compatibility, standards support, behavior, limitations) must include an inline source link where the claim appears — docs page, README section, RFC, release note, or issue. Icon-only cells (`:white_check_mark:`, `:x:`, `:warning:`) need no link; prose cells do.
- **R36** — GitHub repository links in Material ADRs use `[:fontawesome-brands-github: \`org/repo\`](https://github.com/org/repo)` — icon, backtick-wrapped `org/repo`, full GitHub URL. Applies in prose, tables, and column headers. Packages without a GitHub repo: link to primary docs instead; R36 does not apply.
- **R37** — ADR section headings use Material icons: `## :material-text-box-outline: Context`, `## :material-arrow-decision-outline: Decision`, `## :material-arrow-right-bold-outline: Consequences`.
- **R38** — no tautologies in ADR prose or table cells (same fact twice, no new information).
