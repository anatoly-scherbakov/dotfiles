#!/usr/bin/env bash

# Save and restore the i3 workspace tree around applications which restore
# their own sessions (notably Cursor and Google Chrome).
set -euo pipefail

PATH="$HOME/.local/bin:$PATH"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/i3-resurrect"
manifest="$state_dir/workspaces.json"
log_file="$state_dir/session.log"
lock_file="$state_dir/session.lock"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
restore_marker="$runtime_dir/i3-resurrect-restored-$(basename "${I3SOCK:-default}")"

mkdir -p "$state_dir"
exec 9>"$lock_file"
flock -n 9 || exit 0

log() {
  printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" >>"$log_file"
}

require_tools() {
  command -v i3-resurrect >/dev/null
  command -v i3-msg >/dev/null
  command -v jq >/dev/null
}

workspace_id() {
  printf '%s' "$1" | tr -d '/\\:*"<>|'
}

workspace_names() {
  i3-msg -t get_tree | jq -r '
    def real_windows:
      [.. | objects
       | select(.window? != null
                and ((.window_properties.instance // "")
                     | test("^cursor \\(") | not))];
    .. | objects
    | select(.type? == "workspace" and .name != "__i3_scratch")
    | select((real_windows | length) > 0)
    | .name
  '
}

strip_automation_windows() {
  local layout="$1"
  local temporary
  temporary="$(mktemp "$layout.XXXXXX")"

  jq '
    def automation_window:
      (.swallows? // [])
      | any(.instance?; test("^cursor \\("));
    walk(
      if type == "object" and (.nodes? | type == "array") then
        .nodes |= map(select(automation_window | not))
      elif type == "object" and (.floating_nodes? | type == "array") then
        .floating_nodes |= map(select(automation_window | not))
      else . end
    )
  ' "$layout" >"$temporary"
  mv "$temporary" "$layout"
}

save() {
  require_tools

  local staging workspace id old_workspace old_id focused
  local -a workspaces old_workspaces
  mapfile -t workspaces < <(workspace_names)
  focused="$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')"

  staging="$(mktemp -d "$state_dir/.staging.XXXXXX")"
  trap 'rm -rf "$staging"' RETURN

  for workspace in "${workspaces[@]}"; do
    i3-resurrect save -w "$workspace" -d "$staging" \
      --swallow=class,instance,title
    id="$(workspace_id "$workspace")"
    strip_automation_windows "$staging/workspace_${id}_layout.json"
  done

  jq -n --arg focused "$focused" \
    '{focused: $focused, workspaces: $ARGS.positional}' \
    --args "${workspaces[@]}" \
    >"$staging/workspaces.json"

  if [[ -f "$manifest" ]] \
    && jq -e '.workspaces | type == "array"' "$manifest" >/dev/null; then
    mapfile -t old_workspaces < <(jq -r '.workspaces[]?' "$manifest")
  fi

  for workspace in "${workspaces[@]}"; do
    id="$(workspace_id "$workspace")"
    mv "$staging/workspace_${id}_layout.json" "$state_dir/"
    mv "$staging/workspace_${id}_programs.json" "$state_dir/"
  done

  for old_workspace in "${old_workspaces[@]}"; do
    if [[ " ${workspaces[*]} " != *" $old_workspace "* ]]; then
      old_id="$(workspace_id "$old_workspace")"
      rm -f "$state_dir/workspace_${old_id}_layout.json" \
        "$state_dir/workspace_${old_id}_programs.json"
    fi
  done

  mv "$staging/workspaces.json" "$manifest"
  log "saved ${#workspaces[@]} workspaces"
}

start_baseline() {
  pycharm-professional &
  slack &
  google-chrome --password-store=gnome-libsecret &
  /home/anatoly/Telegram/Telegram &
}

start_session_apps() {
  slack &
  /home/anatoly/Telegram/Telegram &
  google-chrome --password-store=gnome-libsecret &
  /home/anatoly/bin/cursor &
}

restore() {
  require_tools

  if [[ -e "$restore_marker" ]]; then
    exit 0
  fi
  : >"$restore_marker"

  if [[ ! -s "$manifest" ]] || ! jq -e '.workspaces | type == "array" and length > 0' "$manifest" >/dev/null; then
    log "no valid snapshot; starting baseline applications"
    start_baseline
    return
  fi

  local workspace focused
  while IFS= read -r workspace; do
    i3-resurrect restore -w "$workspace" -d "$state_dir" --layout-only
  done < <(jq -r '.workspaces[]' "$manifest")

  while IFS= read -r workspace; do
    i3-resurrect restore -w "$workspace" -d "$state_dir" --programs-only
  done < <(jq -r '.workspaces[]' "$manifest")

  # All placeholders now exist, so i3 can swallow session-restored Cursor and
  # Chrome windows into the project workspace where their titles belong.
  start_session_apps

  focused="$(jq -r '.focused // empty' "$manifest")"
  if [[ -n "$focused" ]]; then
    i3-msg "workspace --no-auto-back-and-forth \"$focused\"" >/dev/null
  fi
  log "restored session"
}

autosave() {
  while true; do
    sleep 300
    save || log "autosave failed"
  done
}

case "${1:-}" in
  save) save ;;
  restore) restore ;;
  autosave) autosave ;;
  *)
    echo "Usage: $0 {save|restore|autosave}" >&2
    exit 64
    ;;
esac
