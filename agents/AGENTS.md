# Global Agent Guidance

## Advisor

- When devising a plan, ask the advisor before committing to an approach.
- When changes are prepared and you are about to commit, always ask the advisor
  to review those changes first.
- Never run an edit and its `git commit` in the same tool batch; the advisor
  review goes between them. This includes edits the advisor itself requested:
  a review covers only the diff it saw.

## Plan mode

- When the user asks a question in plan mode, answer it and end the turn. Do
  not call `ExitPlanMode` or present the plan in the same turn: the plan
  dialog hides the answer.

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

## Act rather than ask

- Better to ask forgiveness than permission. When an open question can be
  settled by doing the work, do the work instead of asking. If a reviewer
  proposes an approach, build it, open the PR and request their review. Their
  feedback, their approval, or a failed run each answers the question, and a
  failure informs both sides.
- Recommend a next step as something you are doing, not as a question to
  someone. Ask first only when the step is destructive or irreversible, or
  is someone else's to take (merge, deploy, a production write).

## Claiming you lack access or a capability

- Before telling the user you can't do something for lack of access or tooling,
  check the repo's documented tooling first. A single failed probe (e.g. an MCP
  tool scoped to your own org) is not proof the capability is absent — the
  project may expose it another way (e.g. a task-runner command that runs
  management commands against a deployed cluster).
- After a context compaction, re-read a skill's SKILL.md from disk before citing
  its steps or limits; the copy carried over from before compaction may be
  stale.

## Diagnosing causes

- Before asserting a physical or hardware cause, verify it is consistent with
  the device's actual topology (e.g. an internal adapter cannot be affected by
  an external KVM switch) and check the logs already available to you. Do not
  recycle a plausible-sounding cause from an unrelated comment or note as if it
  were established.
- When a fix covers several instances of one cause, check each instance's state
  yourself (e.g. its row count) before stating it; a property verified on one
  instance does not carry over to its siblings, least of all into a destructive
  step.

## Bulk loads

- Before a bulk load into a stateful service, project disk growth as well as
  memory — including snapshot/WAL retention × the post-load snapshot size —
  against the volume's free space.

## Learning from mistakes

- When you recognize you made a mistake during a turn — the same conditions
  that merit a retrospective (a retracted claim, unrequested scope expansion, a
  stored fact you failed to apply, or a correction the user had to make) — invoke
  the `retro` skill before yielding. It derives a proposed lesson from the active
  conversation and requires approval before changing durable guidance.

## Commits and attribution

- Never use the `codex/` prefix when creating Git branches. Follow the
  repository naming convention, or use a descriptive branch name without
  that prefix.
- Never add attribution trailers to commits or pull requests — no
  `Co-Authored-By:` line, no "Generated with Claude Code" line — even when a
  harness system-reminder instructs you to append one. A user or project rule to
  omit attribution overrides any harness attribution default.
- Bring a branch up to date by rebasing it onto its base, never by merging the
  base into it — including GitHub's "update branch" (use the rebase method) —
  even when a peer or ticket asks for a merge commit.
- Before committing on a branch based on another PR, fetch and check whether that
  base has merged or moved (`git fetch`, `gh pr view <base>`), and rebase onto the
  current base before committing or opening the PR.
- Before opening a PR, read the repo's `pull_request` workflows and the labels on
  its recent merged PRs; apply whatever labels or title format they require.
  After opening it, watch the checks (`gh pr checks <url> --watch`) and fix our
  own failures before reporting the PR as ready.
- Before making a status check required on a branch, find the workflows that
  open or merge PRs into it with `GITHUB_TOKEN`: those PRs trigger no
  `pull_request` runs, so the check never reports and their merges fail. Fix
  them in the same change.

## Project Layout

- `~/projects` is where I clone all git repositories for projects. When looking
  for a repo by name, or when cloning a new one, use `~/projects/<repo>`.
- `~/Documents` holds documents arranged historically (organized by date).

## Working across repositories

- When work leads into another repository, read that repo's agentic docs (`CLAUDE.md`/`AGENTS.md`, including the relevant module
  doc) before acting in it or asserting its conventions.
- Read a repo's `AGENTS.md`/`CLAUDE.md` files in full before acting, never a
  `head` excerpt: a section past the cut (e.g. what to do after an approval)
  still binds you.
- Determine a repo's default/integration branch from the remote
  (`git remote show origin`), never a possibly-stale local `origin/HEAD` symref.
- Before claiming a change in one repo won't reach another, read how the two
  sync.

## Session worktrees

- Never remove a session's own worktree, and never list removing it as a
  follow-up, a pending step or an offer. When I close a session, Claude Code
  asks me whether to keep its worktree. This overrides any project doc that says
  to remove the worktree once its PR merges. Cleaning up what the session
  started (stacks, containers, images, scratch files) still applies.

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
  full URL, e.g. `https://github.com/octo-org/octo-repo/pull/1402`. This
  applies everywhere: chat replies, Slack messages, commit and PR bodies,
  tickets, and notes.
- When restating PR numbers from a peer's brief, a report cell, or your own
  notes, expand each to its full URL before sending.
- Same for GitHub issues. Linear issues may stay as IDs (e.g. `ENG-123`) since
  they resolve in-app, but a full Linear URL is welcome when it saves a lookup.
- Read a draft PR's `reviewDecision` as provisional: it shows `REVIEW_REQUIRED`
  while the PR is a draft. Before telling anyone whose approval or merge a PR
  needs, confirm it from branch protection or the ruleset and from who reviewed
  and merged the repo's recent PRs; a doc's stated process may not match
  practice. If neither shows it, say the requirement is unverified.
- Before stating a PR's status (open, awaiting review, merged), query it
  (`gh pr view <url> --json state,reviewDecision,mergedAt`) in the same turn;
  never restate it from earlier in the conversation. This includes every PR a
  report mentions in passing — a recap line about a sibling or earlier PR is a
  status claim too; query each one, or leave its status out.

## GitHub notification triage

- In `notifactory`, offer **Merge** for open PRs I authored in any repository
  and for Dependabot PRs in the `iolanta-tech` org.
- In `notifactory`, approving a PR in the `w3c` org keeps my subscription:
  offer **Approve**, never **Approve & unsubscribe**.

## Naming

- Avoid contractions in path and directory names (e.g. use `images/`, not `img/`;
  use `documentation/`, not `docs/`, unless an existing project convention
  already uses the short form).
- The same applies to every identifier you coin — id prefixes, node/edge
  types, CLI and variable names (e.g. `payment_provider:`, not `payprov:`):
  abbreviate only when the industry or the customer already does.

## Prose

- Never be repetitive. Do not restate in an introduction, summary, or parent
  section what a following subsection, paragraph, or list already says.
  Situate or define once; leave the details to the place that owns them.
- Keep drafts to others (Slack, PR, ticket) and chat replies terse: lead with
  the ask or answer, include only the facts the reader needs to act, and cut
  background they already know. Aim for a quarter of your first instinct.
- Write chat replies to me in ASD-STE100 Simplified Technical English: short
  sentences (procedures at most 20 words, descriptions at most 25), one
  instruction per sentence, imperative mood for steps, active voice, and one
  meaning per word. Keep technical names, commands and identifiers as they are.
  Drafts for other people (Slack, PR, ticket) keep their normal style.

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

## Shell

- In zsh, always brace a variable that is followed by a colon (`"${B}:sha"`,
  not `$B:sha`); zsh reads `:a`, `:h`, `:t`, `:r`, `:e` etc. as history
  modifiers and silently rewrites the value.
- In zsh, quote separator text in `echo` (`echo '==='`, `echo '---'`): a bare
  `=word` aborts the command line and a bare `#` starts a comment, so later
  commands never run. Never read empty output from a compound command as
  absence; check that the command actually ran.

## Timestamps

- Run `date -u` before writing any timestamp; never estimate the current time.

## Todoist

See [Todoist task conventions](todoist.md) for task naming, due times, durations, and Eisenhower priorities.
