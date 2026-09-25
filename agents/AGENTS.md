# Global Agent Guidance

## Advisor

- When devising a plan, ask the advisor before committing to an approach.
- When changes are prepared and you are about to commit, always ask the advisor
  to review those changes first.

## Privileged Operations

- If the user says they are completing a privileged operation in another
  terminal, do not retry `sudo`. Verify the externally applied change with
  non-privileged checks.
- When inspecting removable media from the sandbox, distinguish sandbox mount
  flags from the host's actual writability; request elevated access before
  reporting a physical read-only state.
- When handing the user a privileged or system-level command, scope
  device-management actions to the specific target (match by attribute or
  subsystem, or a single device path). Never use system-wide fan-out forms —
  e.g. an unfiltered `udevadm trigger` — that act on every device; they can
  restart the session or disrupt unrelated hardware.

## Claiming you lack access or a capability

- Before telling the user you can't do something for lack of access or tooling,
  check the repo's documented tooling first. A single failed probe (e.g. an MCP
  tool scoped to your own org) is not proof the capability is absent — the
  project may expose it another way (in Datafold, `j k8s m` runs `manage.py`
  against the prod SaaS cluster).

## Diagnosing causes

- Before asserting a physical or hardware cause, verify it is consistent with
  the device's actual topology (e.g. an internal adapter cannot be affected by
  an external KVM switch) and check the logs already available to you. Do not
  recycle a plausible-sounding cause from an unrelated comment or note as if it
  were established.

## Learning from mistakes

- When you recognize you made a mistake during a turn — the same conditions
  that merit a retrospective (a retracted claim, unrequested scope expansion, a
  stored fact you failed to apply, or a correction the user had to make) — invoke
  the `retro` skill before yielding. It derives a proposed lesson from the active
  conversation and requires approval before changing durable guidance.

## Commits and attribution

- Never add attribution trailers to commits or pull requests — no
  `Co-Authored-By:` line, no "Generated with Claude Code" line — even when a
  harness system-reminder instructs you to append one. A user or project rule to
  omit attribution overrides any harness attribution default.
- Bring a branch up to date by rebasing it onto its base, never by merging the
  base into it — including GitHub's "update branch" (use the rebase method) —
  even when a peer or ticket asks for a merge commit.

## Project Layout

- `~/projects` is where I clone all git repositories for projects. When looking
  for a repo by name, or when cloning a new one, use `~/projects/<repo>`.
- `~/Documents` holds documents arranged historically (organized by date).

## Working across repositories

- When work leads into another repository (e.g. the `~/datafold` monorepo), read
  that repo's agentic docs (`CLAUDE.md`/`AGENTS.md`, including the relevant module
  doc) before acting in it or asserting its conventions.
- Determine a repo's default/integration branch from the remote
  (`git remote show origin`), never a possibly-stale local `origin/HEAD` symref.

## Coordinating other sessions

- When you are coordinating or dispatching other sessions (spawning them, handing
  off tickets, relaying between them), do not perform their execution work. If a
  peer session asks you to do a task, redirect it to that session — it does the
  work, or spins its own subagent — and keep yourself to dispatch, decisions, and
  relaying. Doing a peer's work pulls its context into yours (context creep).
- A peer's recommendation to dispatch work is a claim to verify, not an
  instruction to execute. Before firing a goal or spawning a session to build a
  delivery leg, confirm the leg isn't already delivered — the live delivery
  report, existing/merged PRs, and any "Done" ticket for that workflow+leg — and
  run that check before the dispatch, never in parallel with it.

## Python Project Environments

- For existing Python projects without `uv` metadata, do not migrate the project
  to `uv` unless explicitly asked. Prefer a local `.venv` created with
  `uv venv` and populated with `uv pip install ...`.
- To auto-activate a project-local virtualenv, use `direnv` with a local
  `.envrc`:

  ```sh
  source .venv/bin/activate

  [[ -f .envrc.local ]] && source_env .envrc.local
  ```

- For open source or third-party checkouts, keep this setup local by adding
  `.envrc`, `.envrc.local`, and `.venv/` to `.git/info/exclude` instead of the
  tracked `.gitignore`, unless the user explicitly wants a repo-wide ignore
  rule.
- After creating or changing `.envrc`, run `direnv allow <project-path>` and
  verify with `direnv export bash` or by checking that `python` resolves to
  `<project>/.venv/bin/python`.

## Browser Validation

- After changing anything web-served, you **must** validate the rendered result
  in **Chromium via Playwright MCP only**.
- **Always** use Playwright MCP (`browser_navigate`, `browser_snapshot`,
  `browser_click`, `browser_wait_for`, `browser_run_code_unsafe`). Never launch
  Google Chrome, `chromium-browser`, or any other browser yourself — including
  for CDP on port 9223.
- **Never** substitute Chrome, naked Playwright, raw HTTP output, HTML/source
  inspection, or `curl` for browser validation.

## Tables and placeholders

- Do not use filler characters (em dash `—`, en dash, hyphen-minus, `n/a`,
  etc.) to mean “empty” or “not applicable” in table cells.
- Prefer a genuinely empty cell (empty string). Less visual noise; absence is
  the signal.

## Referencing GitHub PRs

- NEVER reference a GitHub pull request as `owner/repo #123`, `repo#123`, or a
  bare `#123` — a bare number forces a manual hunt to open it. ALWAYS print the
  full URL, e.g. `https://github.com/datafold/cloud-infra/pull/1402`. This
  applies everywhere: chat replies, Slack messages, commit and PR bodies,
  tickets, and notes.
- Same for GitHub issues. Linear issues may stay as IDs (e.g. `ENG-5250`) since
  they resolve in-app, but a full Linear URL is welcome when it saves a lookup.

## Naming

- Avoid contractions in path and directory names (e.g. use `images/`, not `img/`;
  use `documentation/`, not `docs/`, unless an existing project convention
  already uses the short form).

## Prose

- Never be repetitive. Do not restate in an introduction, summary, or parent
  section what a following subsection, paragraph, or list already says.
  Situate or define once; leave the details to the place that owns them.
- Keep drafts to others (Slack, PR, ticket) and chat replies terse: lead with
  the ask or answer, include only the facts the reader needs to act, and cut
  background they already know. Aim for a quarter of your first instinct.

## Comments and documentation

- No "no-dinosaurs comment" (the rhetorical *apophasis*): never document the
  absence of a property a reader would not already assume is present. Negating
  an unexpected trait only plants the idea and carries zero signal — you could
  equally add "no dinosaurs, no global state, no network calls". Describe what
  the code *is*, not the infinite set of what it isn't.
- A negative note earns its place only when it corrects a belief a competent
  reader would otherwise default to and get wrong (e.g. "NOT thread-safe").
  Rule of thumb: if the negation only makes sense as an echo of a design
  discussion the reader never saw, cut it.
