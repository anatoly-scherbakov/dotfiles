# Handoff: vertical left-edge workspace strip

Implementation brief for an agent working in these dotfiles **on a personal
machine** (not the work machine where this was drafted). Self-contained: it
assumes no access to the conversation that produced it.

## Objective

Move the i3 workspace list off the horizontal top bar and render it as a
**vertical strip down the left edge** of the screen: one workspace per line,
top to bottom.

## Why this is not a polybar tweak

Workspaces are currently drawn by **polybar**, not i3's native bar — see
`[module/i3]` in `polybar/config.ini`. Polybar (3.7.1 here) renders every bar
as a **single horizontal line and has no vertical or multi-line mode** — a
deliberate, long-standing upstream limitation. A narrow left-side polybar would
just clip the workspaces into one horizontal row, not stack them. So the strip
needs a different tool; polybar keeps the top/bottom status bars.

## Chosen approach: a small Python GTK dock

Write a script (suggested `bin/i3-ws-dock.py`, launched from i3) that:

- subscribes to i3 over IPC (`python3-i3ipc`),
- draws a **GTK3 dock window** pinned to the left edge, one clickable label per
  workspace, stacked vertically,
- reserves the strip with `_NET_WM_STRUT_PARTIAL` so tiled windows never sit
  under it.

This was chosen over the alternatives for one decisive reason — the **agent
inbox** (see below) needs a workspace to visibly go *urgent*, and only an
i3-IPC-driven tool guarantees correct urgent + per-output behavior while staying
apt-only. Trade-offs considered:

| Option | apt-only | Urgent highlight | Per-output filter | Cost |
|---|---|---|---|---|
| **Python GTK dock (chosen)** | yes | full control via IPC | exact, via IPC `output` | ~100 lines you own |
| tint2 | yes | via EWMH, unverified under i3 | uncertain under i3 numbering | config-only, but may silently break the agent inbox |
| eww | no (release binary / cargo) | full control | exact | non-apt dependency the user avoids |

Install (all apt-installable). **Do not run these yourself — hand them to the
user to run**, per this repo's agent guidance on privileged operations:

```sh
sudo apt install python3-gi gir1.2-gtk-3.0 python3-i3ipc
```

## Decisions to confirm with the user before building

These were left open at handoff. Ask; do not assume.

1. **Which monitors get the strip.** This machine may differ from the drafting
   one (there it was two 2560×1440 outputs). Today `bar/top-secondary` exists
   *only* to show workspaces on the non-primary output. Options: strip on **both
   outputs** (each filtered to its own workspaces), or **primary only** (the
   second monitor then loses its workspace list — drop `bar/top-secondary`).
2. **Fate of the top bar.** With workspaces removed, `bar/top` holds only the
   tray. Keep it as a compact tray strip, keep it as-is at 48px, or remove it
   and rehome the tray (into the bottom bar or the vertical strip). Either way,
   `bar/top-secondary` becomes empty and should be dropped along with its launch
   loop.

## Requirements the strip must meet

Derived from the current `[module/i3]` and the `setup-agent-inbox` skill. Check
the finished strip against each — do not assume the toolkit gives them for free.

- **Urgent highlighting is load-bearing.** The agent-inbox workflow marks an
  agent's terminal urgent when it needs input; the workspace lights up so the
  user knows where to look, then `bindsym $mod+x [urgent=latest] focus`
  (i3/config) jumps there. The jump works regardless, but the **visual cue is
  the whole point of the strip** — a workspace carrying an urgent window must be
  rendered distinctly (use the `urgent` color below).
- **Per-output filtering** (today's `pin-workspaces = true`): each strip shows
  only the workspaces on its own output (`workspace.output` over IPC).
- **Renamed emoji/symbol workspace names.** Workspaces are renamed via `irene`
  (`$mod+F2`) to names like `1:❶df`, `2:❷news`, `11:➕`, `zoom`. The strip must
  render emoji and dingbats — use Pango markup and a font stack mirroring
  polybar's (DejaVu Sans Mono + Noto Sans Symbols / Symbols2 + Noto Color
  Emoji).
- **Strip workspace numbers for display** (today's `strip-wsnumbers = true`):
  show the label after the leading `N:` (e.g. `❶df`), while still switching to
  the correct workspace on click (switch by workspace name or num, not the
  stripped label).
- **Click to switch** (today's `enable-click = true`): clicking a label runs the
  equivalent of `i3-msg workspace <name>`.
- **Strut reservation:** windows must not render under the strip. Set
  `_NET_WM_STRUT_PARTIAL` for the strip's width on the correct output.
- **Live updates + monitor changes:** subscribe to i3 `workspace` (and `window`,
  for urgent) events so the strip stays current. It must also survive
  plug/unplug — mirror polybar's `screenchange-reload = true` by relaunching or
  re-resolving outputs on `RRScreenChangeNotify` / i3 `output` events.

## Theme (Catppuccin Mocha, from `polybar/config.ini [colors]`)

```
background #1e1e2e   foreground #cdd6f4   accent #89b4fa
active     #cba6f7   urgent     #f38ba8   inactive #6c7086
```

Map to the polybar i3 module's states so the strip reads as the same system:
- **focused:** foreground `background`, background `accent`, padded.
- **visible** (shown on another output): foreground `active`.
- **unfocused:** foreground `inactive`.
- **urgent:** foreground `background`, background `urgent`, padded.

## Files to touch

- **`bin/i3-ws-dock.py`** (new): the dock itself.
- **`install.conf.yaml`** (dotbot): add a link entry so the script is deployed to
  `~/bin`. Scripts here are exposed as **extensionless** symlinks — e.g.
  `~/bin/launch-polybar` → `bin/launch-polybar.sh`. Mirror that:

  ```yaml
      "~/bin/i3-ws-dock":
          path: bin/i3-ws-dock.py
  ```

  (copy the exact options, e.g. `create`/`force`, from the neighboring
  `~/bin/launch-polybar` entry). Re-run `./install` after editing so the symlink
  is created; otherwise `~/bin/i3-ws-dock` will not exist.
- **`polybar/config.ini`**: remove `i3` from `bar/top`'s `modules-left` (leaving
  `tray`, or per the top-bar decision); delete `bar/top-secondary`. Leave the
  `[module/i3]` block only if the top bar decision keeps a polybar workspace
  view anywhere — otherwise remove it too.
- **`bin/launch-polybar.sh`**: drop the `top-secondary` launch loop once that bar
  is gone.
- **`i3/config`**: add `exec_always --no-startup-id ~/bin/i3-ws-dock` (the
  extensionless deployed name, **not** `.py`) near the existing
  `exec_always --no-startup-id ~/bin/launch-polybar` (line ~226). `exec_always`
  so it re-maps after an i3 reload / monitor change.

## Implementation notes

- Prefer a single long-lived process handling all target outputs (one dock
  window per output) over one process per workspace.
- GTK dock window: `Gtk.Window` with type-hint `DOCK`, `set_decorated(False)`,
  skip taskbar/pager, stick, and keep-above; position and size it to the output
  geometry from i3 IPC.
- For strut, set the X property directly (e.g. via `Gdk`/`Xlib`); GTK does not
  reserve struts on its own for a DOCK window on all setups.
- Debounce rapid IPC events to avoid flicker on workspace churn.

## Acceptance / validation

- Workspaces appear stacked vertically on the left of each intended output, in
  i3 order, with emoji names rendered.
- The focused workspace, workspaces on other outputs, and idle workspaces are
  visually distinct per the theme mapping.
- **Trigger an urgent window** (e.g. a terminal that sets the urgency hint) and
  confirm its workspace changes color; `$mod+x` still jumps to it.
- Click a label → i3 switches to that workspace.
- Tiled windows do not overlap the strip (strut works).
- Unplug/replug or reload i3: the strip reappears correctly on each output.
- Top and bottom polybars still launch; no empty/leftover `top-secondary` bar.

## Guardrails for the implementing agent

- **Do not** run `sudo apt install` or fetch binaries yourself — give the command
  to the user and let them run it (the user's global agent guidance on
  privileged operations).
