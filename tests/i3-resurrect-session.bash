#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/bin/i3-resurrect-session.sh"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

fake_home="$temporary/home"
fake_bin="$temporary/bin"
runtime_dir="$temporary/runtime"
app_calls="$temporary/app-calls"
program_restore_calls="$temporary/program-restore-calls"
mkdir -p "$fake_home/bin" "$fake_bin" "$runtime_dir"

cat >"$fake_bin/i3-msg" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "-t get_tree" ]]; then
  jq -n --arg workspace "$FAKE_WORKSPACE" '{
    type: "root",
    nodes: [{
      type: "workspace",
      name: $workspace,
      nodes: [{window: 1, window_properties: {instance: "kitty"}}]
    }]
  }'
elif [[ "$*" == "-t get_workspaces" ]]; then
  jq -n --arg workspace "$FAKE_WORKSPACE" '[{name: $workspace, focused: true}]'
else
  printf '[{"success":true}]\n'
fi
EOF

cat >"$fake_bin/i3-resurrect" <<'EOF'
#!/usr/bin/env bash
action="$1"
shift
workspace=""
directory=""
programs_only=0
while (($#)); do
  case "$1" in
    -w) workspace="$2"; shift 2 ;;
    -d) directory="$2"; shift 2 ;;
    --programs-only) programs_only=1; shift ;;
    *) shift ;;
  esac
done
id="$(printf '%s' "$workspace" | tr -d '/\\:*"<>|')"
if [[ "$action" == save ]]; then
  printf '%s\n' '{"nodes":[
    {"swallows":[{"class":"^kitty$","instance":"^kitty$"}]},
    {"swallows":[{"class":"^Nemo$","instance":"^nemo$"}]},
    {"swallows":[{"instance":"^cursor \\("}]},
    {"swallows":[{"class":"^Google-chrome$"}]}
  ],"floating_nodes":[]}' \
    >"$directory/workspace_${id}_layout.json"
  printf '%s\n' '[
    {"command":["/usr/bin/kitty"]},
    {"command":["/usr/bin/nemo"]},
    {"command":["/usr/bin/slack"]}
  ]' >"$directory/workspace_${id}_programs.json"
elif [[ "$action" == restore ]]; then
  printf '%s\n' "$directory" >>"$FAKE_RESTORE_CALLS"
  if ((programs_only)); then
    jq -r '.[] | (.command | if type == "array" then join(" ") else . end)' \
      "$directory/workspace_${id}_programs.json" \
      | while IFS= read -r command; do
          printf '%s|%s|%s\n' "$directory" "$workspace" "$command" \
            >>"$FAKE_PROGRAM_RESTORE_CALLS"
        done
  fi
  [[ "${FAIL_RESTORE:-0}" != 1 ]]
fi
EOF

chmod +x "$fake_bin/i3-msg" "$fake_bin/i3-resurrect"

for application in slack google-chrome gdbus; do
  cat >"$fake_bin/$application" <<EOF
#!/usr/bin/env bash
printf '%s %s\\n' '$application' "\$*" >>"\$FAKE_APP_CALLS"
EOF
  chmod +x "$fake_bin/$application"
done

for application in "bin/Telegram" "bin/cursor"; do
  cat >"$fake_home/$application" <<EOF
#!/usr/bin/env bash
printf '%s %s\\n' '$application' "\$*" >>"\$FAKE_APP_CALLS"
EOF
  chmod +x "$fake_home/$application"
done

cat >"$fake_bin/nemo" <<'EOF'
#!/usr/bin/env bash
printf 'nemo %s\n' "$*" >>"$FAKE_APP_CALLS"
EOF
chmod +x "$fake_bin/nemo"

run_helper() {
  env \
    HOME="$fake_home" \
    PATH="$fake_bin:$PATH" \
    XDG_STATE_HOME="$1" \
    XDG_RUNTIME_DIR="$runtime_dir" \
    FAKE_WORKSPACE="$2" \
    FAKE_RESTORE_CALLS="$temporary/restore-calls" \
    FAKE_PROGRAM_RESTORE_CALLS="$program_restore_calls" \
    FAKE_APP_CALLS="$app_calls" \
    SECRET_SERVICE_TIMEOUT_SECONDS="${SECRET_SERVICE_TIMEOUT_SECONDS:-30}" \
    bash "$script" "${@:3}"
}

state="$temporary/state"
run_helper "$state" alpha save
jq -e '.workspaces == ["alpha"]' \
  "$state/i3-resurrect/current/workspaces.json" >/dev/null
jq -e '
  [.. | objects | .swallows? // empty | .[]?]
  | all(((.class? // "") + (.instance? // "")) | test("kitty|cursor|nemo"; "i") | not)
' "$state/i3-resurrect/current/workspace_alpha_layout.json" >/dev/null
jq -e '
  [.. | objects | .swallows? // empty | .[]?]
  | any(.class == "^Google-chrome$")
' "$state/i3-resurrect/current/workspace_alpha_layout.json" >/dev/null
jq -e '
  any(.[]; (.command[0] // "") == "/usr/bin/kitty") | not
' "$state/i3-resurrect/current/workspace_alpha_programs.json" >/dev/null
jq -e '
  any(.[]; (.command[0] // "") == "/usr/bin/nemo") | not
' "$state/i3-resurrect/current/workspace_alpha_programs.json" >/dev/null
jq -e '
  any(.[]; (.command[0] // "") == "/usr/bin/slack")
' "$state/i3-resurrect/current/workspace_alpha_programs.json" >/dev/null

run_helper "$state" beta save
jq -e '.workspaces == ["beta"]' \
  "$state/i3-resurrect/current/workspaces.json" >/dev/null
jq -e '.workspaces == ["alpha"]' \
  "$state/i3-resurrect/previous/workspaces.json" >/dev/null

legacy_state="$temporary/legacy-state/i3-resurrect"
mkdir -p "$legacy_state"
printf '{"focused":"legacy","workspaces":["legacy"]}\n' \
  >"$legacy_state/workspaces.json"
printf '{"nodes":[],"floating_nodes":[]}\n' \
  >"$legacy_state/workspace_legacy_layout.json"
printf '[]\n' >"$legacy_state/workspace_legacy_programs.json"
run_helper "$temporary/legacy-state" fresh save
jq -e '.workspaces == ["fresh"]' \
  "$legacy_state/current/workspaces.json" >/dev/null
jq -e '.workspaces == ["legacy"]' \
  "$legacy_state/previous/workspaces.json" >/dev/null

autosave_state="$temporary/autosave-state"
run_helper "$autosave_state" alpha autosave &
autosave_pid=$!
for _ in 1 2 3 4 5; do
  [[ -e "$autosave_state/i3-resurrect/session.lock" ]] && break
  sleep 0.1
done
flock -n "$autosave_state/i3-resurrect/session.lock" -c true
kill "$autosave_pid"
wait "$autosave_pid" 2>/dev/null || true

serial_state="$temporary/serial-state"
mkdir -p "$serial_state/i3-resurrect"
flock "$serial_state/i3-resurrect/session.lock" sleep 1 &
locker_pid=$!
sleep 0.1
run_helper "$serial_state" serialized save &
save_pid=$!
sleep 0.1
kill -0 "$save_pid"
wait "$locker_pid"
wait "$save_pid"
jq -e '.workspaces == ["serialized"]' \
  "$serial_state/i3-resurrect/current/workspaces.json" >/dev/null

restore_state="$temporary/restore-state"
run_helper "$restore_state" restored save
jq -n --arg home "$fake_home" '[
  {command: ["/usr/bin/nemo"], working_directory: $home},
  {command: ["/usr/bin/kitty"], working_directory: $home},
  {command: ["/usr/bin/google-chrome"], working_directory: $home},
  {command: ["/home/test/bin/Telegram"], working_directory: $home}
]' >"$restore_state/i3-resurrect/current/workspace_restored_programs.json"
rm -f "$temporary/restore-calls" "$program_restore_calls" "$app_calls" \
  "$runtime_dir"/i3-resurrect-restored-*
run_helper "$restore_state" restored restore
for _ in 1 2 3 4 5; do
  [[ -s "$app_calls" ]] && break
  sleep 0.1
done
if [[ -s "$program_restore_calls" ]] \
  && rg -F '|/usr/bin/kitty' "$program_restore_calls" >/dev/null; then
  echo "Kitty was replayed through i3-resurrect" >&2
  exit 1
fi
if [[ -s "$program_restore_calls" ]] \
  && rg -F '/usr/bin/nemo' "$program_restore_calls" >/dev/null; then
  echo "Nemo was replayed through i3-resurrect" >&2
  exit 1
fi
if [[ -s "$program_restore_calls" ]] \
  && rg -F '/usr/bin/google-chrome' "$program_restore_calls" >/dev/null; then
  echo "Chrome was replayed through i3-resurrect" >&2
  exit 1
fi
if [[ -s "$program_restore_calls" ]] \
  && rg -F '/home/test/bin/Telegram' "$program_restore_calls" >/dev/null; then
  echo "Telegram was replayed through i3-resurrect" >&2
  exit 1
fi
rg -Fx 'google-chrome --password-store=gnome-libsecret --restore-last-session' \
  "$app_calls" >/dev/null
rg -Fx 'bin/Telegram ' "$app_calls" >/dev/null

timeout_state="$temporary/timeout-state"
run_helper "$timeout_state" timeout save
rm -f "$app_calls" "$runtime_dir"/i3-resurrect-restored-*
SECRET_SERVICE_TIMEOUT_SECONDS=0 run_helper "$timeout_state" timeout restore
sleep 0.1
if [[ -e "$app_calls" ]] && rg -F 'google-chrome ' "$app_calls" >/dev/null; then
  echo "Chrome started without GNOME Secret Service" >&2
  exit 1
fi
rg -F 'Chrome session restore not started: GNOME Secret Service unavailable (wait limit: 0 seconds)' \
  "$timeout_state/i3-resurrect/session.log" >/dev/null

printf '{broken\n' >"$state/i3-resurrect/current/workspaces.json"
rm -f "$temporary/restore-calls" "$runtime_dir"/i3-resurrect-restored-*
if env \
  HOME="$fake_home" \
  PATH="$fake_bin:$PATH" \
  XDG_STATE_HOME="$state" \
  XDG_RUNTIME_DIR="$runtime_dir" \
  FAKE_WORKSPACE=unused \
  FAKE_RESTORE_CALLS="$temporary/restore-calls" \
  FAKE_PROGRAM_RESTORE_CALLS="$program_restore_calls" \
  FAKE_APP_CALLS="$app_calls" \
  FAIL_RESTORE=1 \
  bash "$script" restore; then
  echo "restore unexpectedly succeeded" >&2
  exit 1
fi
grep -Fx "$state/i3-resurrect/previous" "$temporary/restore-calls" >/dev/null
if compgen -G "$runtime_dir/i3-resurrect-restored-*" >/dev/null; then
  echo "failed restore created a marker" >&2
  exit 1
fi

echo "i3-resurrect session tests passed"
