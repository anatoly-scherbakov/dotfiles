#!/usr/bin/env bash

# Save and restore the i3 workspace tree around applications which restore
# their own sessions (notably Cursor and Google Chrome).
set -Eeuo pipefail

PATH="$HOME/.local/bin:$PATH"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/i3-resurrect"
current_dir="$state_dir/current"
previous_dir="$state_dir/previous"
log_file="$state_dir/session.log"
lock_file="$state_dir/session.lock"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
restore_marker="$runtime_dir/i3-resurrect-restored-$(basename "${I3SOCK:-default}")"
operation="${1:-unknown}"

mkdir -p "$state_dir"

log() {
  printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" >>"$log_file"
}

on_error() {
  local status=$?
  trap - ERR
  log "$operation failed (exit $status)"
  exit "$status"
}
trap on_error ERR

require_tools() {
  command -v i3-resurrect >/dev/null
  command -v i3-msg >/dev/null
  command -v jq >/dev/null
}

workspace_id() {
  printf '%s' "$1" | tr -d '/\\:*"<>|'
}

valid_generation() {
  local directory="$1" workspace id

  [[ -s "$directory/workspaces.json" ]] || return 1
  jq -e '.workspaces | type == "array"' \
    "$directory/workspaces.json" >/dev/null 2>&1 || return 1

  while IFS= read -r workspace; do
    id="$(workspace_id "$workspace")"
    [[ -s "$directory/workspace_${id}_layout.json" ]] || return 1
    [[ -s "$directory/workspace_${id}_programs.json" ]] || return 1
    jq empty "$directory/workspace_${id}_layout.json" \
      "$directory/workspace_${id}_programs.json" \
      >/dev/null 2>&1 || return 1
  done < <(jq -r '.workspaces[]' "$directory/workspaces.json")
}

migrate_legacy_snapshot() {
  local migration
  local -a files

  if [[ -e "$current_dir" || ! -s "$state_dir/workspaces.json" ]]; then
    return
  fi

  migration="$(mktemp -d "$state_dir/.migration.XXXXXX")"
  shopt -s nullglob
  files=(
    "$state_dir"/workspace_*_layout.json
    "$state_dir"/workspace_*_programs.json
  )
  shopt -u nullglob

  if ((${#files[@]})); then
    mv "${files[@]}" "$migration/"
  fi
  mv "$state_dir/workspaces.json" "$migration/"
  mv "$migration" "$current_dir"
  log "migrated legacy snapshot"
}

run_locked() {
  exec 9>"$lock_file"
  if ! flock -n 9; then
    log "$operation waiting for lock"
    flock 9
  fi

  migrate_legacy_snapshot
  "$@"
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

promote_generation() {
  local staging="$1"

  if [[ -d "$current_dir" ]]; then
    rm -rf "$previous_dir"
    mv "$current_dir" "$previous_dir"
  fi
  mv "$staging" "$current_dir"
}

save_session() {
  require_tools
  log "save started"

  local staging workspace id focused
  local -a workspaces
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

  valid_generation "$staging"
  promote_generation "$staging"
  trap - RETURN
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

generation_to_restore() {
  if valid_generation "$current_dir"; then
    printf '%s\n' "$current_dir"
  elif valid_generation "$previous_dir"; then
    log "current snapshot invalid; restoring previous snapshot"
    printf '%s\n' "$previous_dir"
  else
    return 1
  fi
}

restore_session() {
  require_tools
  log "restore started"

  if [[ -e "$restore_marker" ]]; then
    log "restore skipped; session already restored"
    return
  fi

  local snapshot manifest workspace focused
  if ! snapshot="$(generation_to_restore)" \
    || ! jq -e '.workspaces | length > 0' \
      "$snapshot/workspaces.json" >/dev/null; then
    log "no valid snapshot; starting baseline applications"
    start_baseline
    : >"$restore_marker"
    return
  fi
  manifest="$snapshot/workspaces.json"

  log "restoring $(jq '.workspaces | length' "$manifest") workspaces"
  while IFS= read -r workspace; do
    i3-resurrect restore -w "$workspace" -d "$snapshot" --layout-only
  done < <(jq -r '.workspaces[]' "$manifest")

  while IFS= read -r workspace; do
    i3-resurrect restore -w "$workspace" -d "$snapshot" --programs-only
  done < <(jq -r '.workspaces[]' "$manifest")

  # All placeholders now exist, so i3 can swallow session-restored Cursor and
  # Chrome windows into the project workspace where their titles belong.
  start_session_apps

  focused="$(jq -r '.focused // empty' "$manifest")"
  if [[ -n "$focused" ]]; then
    i3-msg "workspace --no-auto-back-and-forth \"$focused\"" >/dev/null
  fi
  : >"$restore_marker"
  log "restored session"
}

autosave() {
  log "autosave started"
  while true; do
    sleep 300
    if ! bash "${BASH_SOURCE[0]}" save; then
      log "autosave failed"
    fi
  done
}

case "$operation" in
  save) run_locked save_session ;;
  restore) run_locked restore_session ;;
  autosave) autosave ;;
  *)
    echo "Usage: $0 {save|restore|autosave}" >&2
    exit 64
    ;;
esac
