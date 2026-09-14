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
3. **Compose the prompt.** If the user is handing off work from the *current*
   session, write a **self-contained brief** as the prompt — the new session
   knows nothing. Include the repository, the branch or worktree, what is already
   done, what to do next, and the key file paths. If the user gave explicit
   prompt text, pass it verbatim.
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
