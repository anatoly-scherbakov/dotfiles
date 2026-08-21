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

resolve_binary() {
  local variable_name="$1"
  local default_name="$2"
  local candidate="${!variable_name:-$default_name}"
  local resolved

  if [[ "$candidate" == */* ]]; then
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  elif resolved="$(command -v "$candidate" 2>/dev/null)"; then
    printf '%s\n' "$resolved"
    return
  fi

  log "${variable_name} executable unavailable: $candidate"
  return 1
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

strip_unrestored_windows() {
  local layout="$1"
  local temporary
  temporary="$(mktemp "$layout.XXXXXX")"

  jq '
    def kitty_window:
      [(.class? // ""), (.instance? // "")]
      | any(test("kitty"; "i"));
    def cursor_window:
      (.instance? // "") | test("cursor"; "i");
    def unrestored_window:
      (.swallows? // [])
      | any(
          cursor_window
          or kitty_window
        );
    walk(
      if type == "object" and (.nodes? | type == "array") then
        .nodes |= map(select(unrestored_window | not))
      elif type == "object" and (.floating_nodes? | type == "array") then
        .floating_nodes |= map(select(unrestored_window | not))
      else . end
    )
  ' "$layout" >"$temporary"
  mv "$temporary" "$layout"
}

strip_kitty_programs() {
  local programs="$1"
  local temporary
  temporary="$(mktemp "$programs.XXXXXX")"

  jq '
    def executable:
      .command as $command
      | if ($command | type) == "array" then ($command[0] // "")
        elif ($command | type) == "string" then $command
        else ""
        end;
    def basename: executable | split("/") | last | split(" ")[0];
    map(select((basename | test("^kitty$"; "i")) | not))
  ' "$programs" >"$temporary"
  mv "$temporary" "$programs"
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
    strip_unrestored_windows "$staging/workspace_${id}_layout.json"
    strip_kitty_programs "$staging/workspace_${id}_programs.json"
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
  start_chrome
  start_telegram
}

start_session_apps() {
  slack &
  start_telegram
  start_chrome
  "$HOME/bin/cursor" &
}

wait_for_secret_service() {
  local gdbus_bin timeout_seconds attempt

  if ! gdbus_bin="$(resolve_binary GDBUS_BIN gdbus)"; then
    return 1
  fi

  timeout_seconds="${SECRET_SERVICE_TIMEOUT_SECONDS:-30}"
  if ! [[ "$timeout_seconds" =~ ^[0-9]+$ ]]; then
    log "invalid SECRET_SERVICE_TIMEOUT_SECONDS: $timeout_seconds; using 30"
    timeout_seconds=30
  fi

  for ((attempt = 0; attempt < timeout_seconds; attempt++)); do
    if "$gdbus_bin" call --session \
      --dest org.freedesktop.secrets \
      --object-path /org/freedesktop/secrets \
      --method org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  return 1
}

start_chrome() {
  local chrome_bin

  if ! chrome_bin="$(resolve_binary CHROME_BIN google-chrome)"; then
    return
  fi

  (
    if ! wait_for_secret_service; then
      log "Chrome session restore not started: GNOME Secret Service unavailable (wait limit: ${SECRET_SERVICE_TIMEOUT_SECONDS:-30} seconds)"
      return
    fi

    log "starting Chrome session restore: $chrome_bin"
    if "$chrome_bin" --password-store=gnome-libsecret --restore-last-session \
      >>"$state_dir/chrome.log" 2>&1; then
      log "Chrome session restore process exited"
    else
      log "Chrome session restore process exited with status $?"
    fi
  ) &
  log "queued Chrome session restore: $chrome_bin"
}

start_telegram() {
  local telegram_bin

  if ! telegram_bin="$(resolve_binary TELEGRAM_BIN "$HOME/bin/Telegram")"; then
    log "Telegram was not started; set TELEGRAM_BIN or install it at $HOME/bin/Telegram"
    return
  fi

  "$telegram_bin" >>"$state_dir/telegram.log" 2>&1 &
  log "started Telegram: $telegram_bin"
}

snapshot_has_nemo() {
  local snapshot="$1"
  local programs

  shopt -s nullglob
  for programs in "$snapshot"/workspace_*_programs.json; do
    if jq -e '
      def executable:
        .command as $command
        | if ($command | type) == "array" then ($command[0] // "")
          elif ($command | type) == "string" then $command
          else ""
          end;
      any(.[]; (executable | split("/") | last | split(" ")[0]) == "nemo")
    ' "$programs" >/dev/null; then
      shopt -u nullglob
      return 0
    fi
  done
  shopt -u nullglob
  return 1
}

prepare_program_restore_directories() {
  local snapshot="$1"
  local nemo_bin="$2"
  local programs temporary

  program_restore_dir="$(mktemp -d "$state_dir/.program-restore.XXXXXX")"
  nemo_restore_dir="$(mktemp -d "$state_dir/.nemo-restore.XXXXXX")"
  cp -a "$snapshot"/. "$program_restore_dir"/
  cp -a "$snapshot"/. "$nemo_restore_dir"/

  shopt -s nullglob
  for programs in "$program_restore_dir"/workspace_*_programs.json; do
    temporary="$(mktemp "$programs.XXXXXX")"
    jq '
      def executable:
        .command as $command
        | if ($command | type) == "array" then ($command[0] // "")
          elif ($command | type) == "string" then $command
          else ""
          end;
      def basename: executable | split("/") | last | split(" ")[0];
      map(select(
        (basename == "nemo"
         or basename == "google-chrome"
         or basename == "google-chrome-stable"
         or basename == "chromium"
         or basename == "chromium-browser"
         or basename == "chrome"
         or basename == "cursor"
         or basename == "Telegram"
         or basename == "telegram"
         or basename == "kitty") | not
      ))
    ' "$programs" >"$temporary"
    mv "$temporary" "$programs"
  done

  for programs in "$nemo_restore_dir"/workspace_*_programs.json; do
    temporary="$(mktemp "$programs.XXXXXX")"
    jq --arg nemo_bin "$nemo_bin" '
      def executable:
        .command as $command
        | if ($command | type) == "array" then ($command[0] // "")
          elif ($command | type) == "string" then $command
          else ""
          end;
      def basename: executable | split("/") | last | split(" ")[0];
      map(
        select(basename == "nemo")
        | .command |= if type == "array" then [$nemo_bin] + .[1:]
                      elif type == "string" then $nemo_bin + sub("^[^ ]+"; "")
                      else [$nemo_bin]
                      end
      )
    ' "$programs" >"$temporary"
    mv "$temporary" "$programs"
  done
  shopt -u nullglob
}

cleanup_program_restore_directories() {
  [[ -n "${program_restore_dir:-}" ]] && rm -rf "$program_restore_dir"
  [[ -n "${nemo_restore_dir:-}" ]] && rm -rf "$nemo_restore_dir"
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

  local snapshot manifest workspace focused nemo_bin=""
  local program_restore_dir="" nemo_restore_dir=""
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

  if snapshot_has_nemo "$snapshot"; then
    if nemo_bin="$(resolve_binary NEMO_BIN nemo)"; then
      log "restoring Nemo placeholders with $nemo_bin"
    else
      log "Nemo placeholders were not restored because Nemo is unavailable"
    fi
  fi
  prepare_program_restore_directories "$snapshot" "$nemo_bin"

  while IFS= read -r workspace; do
    i3-resurrect restore -w "$workspace" -d "$program_restore_dir" --programs-only
  done < <(jq -r '.workspaces[]' "$manifest")

  if [[ -n "$nemo_bin" ]]; then
    while IFS= read -r workspace; do
      i3-resurrect restore -w "$workspace" -d "$nemo_restore_dir" --programs-only
    done < <(jq -r '.workspaces[]' "$manifest")
  fi
  cleanup_program_restore_directories

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
