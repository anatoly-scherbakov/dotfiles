#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/bin/i3-resurrect-session.sh"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

fake_home="$temporary/home"
fake_bin="$temporary/bin"
runtime_dir="$temporary/runtime"
mkdir -p "$fake_home" "$fake_bin" "$runtime_dir"

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
while (($#)); do
  case "$1" in
    -w) workspace="$2"; shift 2 ;;
    -d) directory="$2"; shift 2 ;;
    *) shift ;;
  esac
done
id="$(printf '%s' "$workspace" | tr -d '/\\:*"<>|')"
if [[ "$action" == save ]]; then
  printf '{"nodes":[],"floating_nodes":[]}\n' \
    >"$directory/workspace_${id}_layout.json"
  printf '[]\n' >"$directory/workspace_${id}_programs.json"
elif [[ "$action" == restore ]]; then
  printf '%s\n' "$directory" >>"$FAKE_RESTORE_CALLS"
  [[ "${FAIL_RESTORE:-0}" != 1 ]]
fi
EOF

chmod +x "$fake_bin/i3-msg" "$fake_bin/i3-resurrect"

run_helper() {
  env \
    HOME="$fake_home" \
    PATH="$fake_bin:$PATH" \
    XDG_STATE_HOME="$1" \
    XDG_RUNTIME_DIR="$runtime_dir" \
    FAKE_WORKSPACE="$2" \
    FAKE_RESTORE_CALLS="$temporary/restore-calls" \
    bash "$script" "${@:3}"
}

state="$temporary/state"
run_helper "$state" alpha save
jq -e '.workspaces == ["alpha"]' \
  "$state/i3-resurrect/current/workspaces.json" >/dev/null

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

printf '{broken\n' >"$state/i3-resurrect/current/workspaces.json"
rm -f "$temporary/restore-calls" "$runtime_dir"/i3-resurrect-restored-*
if env \
  HOME="$fake_home" \
  PATH="$fake_bin:$PATH" \
  XDG_STATE_HOME="$state" \
  XDG_RUNTIME_DIR="$runtime_dir" \
  FAKE_WORKSPACE=unused \
  FAKE_RESTORE_CALLS="$temporary/restore-calls" \
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
