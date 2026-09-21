---
name: spawn-claude
description: Spawn a fresh, foreground Claude session in its own kitty window in a chosen project directory — optionally with an initial prompt, plan mode, or a worktree — to offload work to a window you Alt-Tab to.
disable-model-invocation: true
---

# spawn-claude

Use this user-invoked skill to hand a task to a **new** Claude session running in
its **own kitty window**. i3 adopts the window like any hand-opened terminal, so
it lives in the workspace and is reached by Alt-Tab / `Mod4+x`.

The new session starts with **zero context** from the current one and may run in
a **different project** than the current session.

## Mechanism

The `~/bin/spawn-claude` helper (`bin/spawn-claude.sh` in this repo) opens the
window: `spawn-claude DIR [claude-arg ...]`. It resolves `DIR`, opens a detached
kitty window whose cwd is `DIR`, and runs `claude` there with every remaining
argument forwarded verbatim. When claude exits, the window drops to an
interactive shell in the same directory instead of closing.

The helper clears the Claude Code session markers (`CLAUDE_CODE_CHILD_SESSION`,
`CLAUDE_CODE_SESSION_ID`, `CLAUDE_CODE_MESSAGING_SOCKET`/`_TOKEN`, `CLAUDE_PID`,
`CLAUDECODE`) that leak in when it is launched from inside a Claude session, so
the new window is a genuine top-level session with its own transcript
persistence rather than a marked child of the caller.

## Workflow

1. From the user's request, determine:
   - **Target directory** (required).
   - **Initial prompt** (optional) — what the new session should start on.
   - **Flags** (optional) — pass through `--permission-mode plan` for plan mode
     and/or `--worktree [name]` for an isolated git worktree.
2. **Resolve the directory** using the user's project-layout convention: an
   absolute or `~` path is used as given; a bare repository name resolves to
   `~/projects/<name>` first, then `~/<name>` (so `datafold` → `~/datafold`).
   The helper applies the same rule, so a bare name may be passed straight
   through. Only ask the user if the directory cannot be found.
3. **Compose the prompt — keep it concise; do not duplicate a durable spec.**
   When the work is already captured somewhere the new session can open — a
   Linear ticket, a design doc, a PR — make the prompt a **short pointer** to it,
   e.g. `Address ENG-1234` (add its URL or repo only if that helps it find the
   thing). The new session reads the source itself; re-narrating the ticket's
   contents into the prompt is wasteful repetition. Only write a longer
   self-contained brief when there is **no** such durable source — and then
   include just what the new session can't recover on its own (repository,
   branch/worktree, what's already done, what to do next, key file paths). If the
   user gave explicit prompt text, pass it verbatim.

   **Always append a one-line pingback** (unless the user says not to). After the
   task pointer, add a single sentence telling the new session to report back:
   read **your own** session name from `ListAgents` (the `This session is <name>`
   line at the top) and instruct the new session to `SendMessage` that name a
   one-line status when the work is complete (PR opened/updated/merged) or if it
   stops blocked — e.g. `When done or blocked, SendMessage to drivetime-queue
   with a one-line status.` The task detail stays in the ticket; this line is the
   only coordination the prompt adds. The pingback relies on the new window being
   a genuine top-level session (see Mechanism) — a marked child can't be
   messaged, so it would silently never arrive.
4. **Launch** by running the helper, forwarding flags before the prompt:

   ```sh
   spawn-claude <dir> [--permission-mode plan] [--worktree <name>] ["<prompt>"]
   ```

   Examples:

   ```sh
   spawn-claude datafold "audit the flaky auth test and propose a fix"
   spawn-claude abstractor --permission-mode plan "design the new parser"
   spawn-claude ~/projects/datafold-commander            # no prompt: ready to type
   ```

5. **Confirm** the window launched — the helper prints `launched claude in <dir>`;
   optionally verify with `pgrep -af 'kitty --directory'`. Report the directory
   the session opened in.

## Boundaries

- This spawns an independent window; it is not a background agent and there is
  no attach/detach. Do not use `--bg` or `claude agents` for this.
- Launch exactly one window per request unless the user asks for several.
- If the helper reports a missing directory, `kitty`, or `setsid`, relay that and
  stop rather than guessing an alternative.
