---
name: setup-agent-inbox
description: >-
  Set up the i3 "agent inbox" on this machine so Claude Code and Codex mark
  their kitty terminal urgent when they need input or finish a turn — the
  workspace lights up in polybar and Mod4+x jumps to the waiting agent. Use when
  the user asks to set up / repair the agent inbox or agent notifications, or
  after cloning these dotfiles onto a new machine. Idempotent: safe to re-run.
---

# setup-agent-inbox

Makes every waiting Claude Code / Codex agent announce itself instead of forcing
the user to hop across i3 workspaces to find which one needs them.

## How it works

Each agent rings the **terminal bell** when it wants attention. kitty (at its
defaults: `window_alert_on_bell yes`, `enable_audio_bell yes`) turns a bell into
an X11 **urgency hint** plus a sound. i3 marks that window urgent, polybar's
`[module/i3]` `label-urgent` paints the workspace pink, and `Mod4+x`
(`[urgent=latest] focus`) jumps to it — repeat to cycle through several.

- **Codex** rings the bell natively via `[tui]` config — no script.
- **Claude Code** rings it natively via `preferredNotifChannel: "terminal_bell"`
  — Claude owns its terminal (pts) and writes the bell itself when it needs
  permission (~6s) or has been idle waiting for you (~60s). Hooks can't do this:
  they run without a controlling terminal, so a hook's bell never reaches kitty.

This skill only edits: the tracked `i3/config` (the keybind) and the two
**standalone, private** config files `~/.claude/settings.json` and
`~/.codex/config.toml` (never symlink those into this public repo — they hold
`autoMode` engagement context and per-project `trust_level` paths). Every step
checks before it writes, so re-running changes nothing.

## Prerequisites

`jq` and `awk` (present on the target machines). kitty is the terminal; the agent
must run **directly** in kitty, not nested in tmux (tmux swallows the bell unless
`monitor-bell` propagates).

## Steps

### 1. i3 keybind (tracked in this repo)

Ensure `~/dotfiles/i3/config` binds the jump key, then reload i3:

```sh
grep -qF 'bindsym $mod+x [urgent=latest] focus' ~/dotfiles/i3/config \
  || printf '\n# Jump to the most recently urgent window (a waiting agent).\nbindsym $mod+x [urgent=latest] focus\n' >> ~/dotfiles/i3/config
i3-msg reload >/dev/null
```

### 2. Claude Code native bell (`~/.claude/settings.json`, standalone)

Enable the built-in terminal-bell channel. Claude writes the BEL to its own pts,
so it reaches kitty (a hook can't — it runs without a controlling terminal). This
rings when Claude needs permission (~6s) or is idle waiting for you (~60s), i.e.
whenever an agent is waiting on you. Idempotent, and leaves all other settings
untouched:

```sh
f=~/.claude/settings.json
jq '.preferredNotifChannel = "terminal_bell"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
```

Verify: `jq -r '.preferredNotifChannel' ~/.claude/settings.json` prints
`terminal_bell`.

### 3. Codex TUI notifications (`~/.codex/config.toml`, standalone)

Add three keys to the existing `[tui]` table (only if absent), which makes Codex
ring the bell on both turn-completion and approval prompts when unfocused:

```sh
f=~/.codex/config.toml
grep -qF 'notification_method = "bel"' "$f" || awk '
  1
  /^\[tui\]$/ {
    print "notifications = [\"agent-turn-complete\", \"approval-requested\"]"
    print "notification_method = \"bel\""
    print "notification_condition = \"unfocused\""
  }
' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
```

This inserts the keys right after the `[tui]` header, before any `[tui.*]`
sub-table (required by TOML). Verify Codex still starts: `codex --version`.

## Verify end-to-end

1. Focus another workspace, then in an agent's kitty window run
   `printf '\a' > /dev/tty` — the workspace turns pink in polybar; `Mod4+x` jumps
   to it and clears it.
2. Claude, unfocused/away: a permission prompt (~6s) or sitting idle after a turn
   (~60s) rings the bell → the workspace goes urgent.
3. Codex, unfocused: trigger a tool approval and a turn completion — both ring.
4. Two agents urgent at once → repeated `Mod4+x` cycles between them.
5. Re-run this skill → every step reports already-present, nothing changes.
