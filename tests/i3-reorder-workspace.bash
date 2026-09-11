#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/bin/i3-reorder-workspace.sh"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

fake_bin="$temporary/bin"
mkdir -p "$fake_bin"

cat >"$fake_bin/i3-msg" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "-t" && "${2:-}" == "get_workspaces" ]]; then
  cat "$FAKE_WORKSPACES"
  exit 0
fi
if [[ "${1:-}" == "rename" && "${2:-}" == "workspace" ]]; then
  from="$3"
  to="$5"
  # Mirror i3: names starting with "__" are reserved as i3-internal.
  if [[ "$to" == __* ]]; then
    printf 'ERROR: Cannot rename workspace to "%s": names starting with __ are i3-internal.\n' "$to" >&2
    exit 2
  fi
  printf '%s -> %s\n' "$from" "$to" >>"$FAKE_RENAMES"
  jq --arg from "$from" --arg to "$to" '
    map(
      if .name == $from then
        .name = $to
        | .num = (
            if ($to | test("^[0-9]+"))
            then ($to | match("^[0-9]+").string | tonumber)
            else -1
            end
          )
      else .
      end
    )
  ' "$FAKE_WORKSPACES" >"$FAKE_WORKSPACES.tmp"
  mv "$FAKE_WORKSPACES.tmp" "$FAKE_WORKSPACES"
  printf '[{"success":true}]\n'
  exit 0
fi
printf 'unexpected i3-msg: %s\n' "$*" >&2
exit 1
EOF
chmod +x "$fake_bin/i3-msg"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  cat "$FAKE_WORKSPACES" >&2 || true
  [[ -f "$FAKE_RENAMES" ]] && cat "$FAKE_RENAMES" >&2 || true
  exit 1
}

write_workspaces() {
  jq -n "$1" >"$FAKE_WORKSPACES"
  : >"$FAKE_RENAMES"
}

run_reorder() {
  env \
    PATH="$fake_bin:$PATH" \
    FAKE_WORKSPACES="$FAKE_WORKSPACES" \
    FAKE_RENAMES="$FAKE_RENAMES" \
    bash "$script" "$1"
}

workspace_name() {
  jq -r '.[] | select(.focused==true).name' "$FAKE_WORKSPACES"
}

workspace_by_num() {
  local num="$1"
  jq -r --argjson n "$num" '.[] | select(.num == $n).name' "$FAKE_WORKSPACES"
}

rename_count() {
  wc -l <"$FAKE_RENAMES" | tr -d ' '
}

FAKE_WORKSPACES="$temporary/workspaces.json"
FAKE_RENAMES="$temporary/renames.log"

# hole: workspaces 1 and 3, focus 3, left → current becomes 2
write_workspaces '[
  {"name":"1","num":1,"focused":false},
  {"name":"3:❸chat","num":3,"focused":true}
]'
run_reorder left
[[ "$(workspace_name)" == "2:❷chat" ]] || fail "hole left: expected 2:❷chat"
[[ "$(rename_count)" == "1" ]] || fail "hole left: expected one rename"

# swap: 2 and 3, focus 3, left → 2↔3 with irene titles
write_workspaces '[
  {"name":"2:❷news","num":2,"focused":false},
  {"name":"3:❸chat","num":3,"focused":true}
]'
run_reorder left
[[ "$(workspace_by_num 2)" == "2:❷chat" ]] || fail "swap: chat should be 2"
[[ "$(workspace_by_num 3)" == "3:❸news" ]] || fail "swap: news should be 3"
[[ "$(workspace_name)" == "2:❷chat" ]] || fail "swap: focus should stay on chat"

# floor: focus 1, left → no rename
write_workspaces '[{"name":"1","num":1,"focused":true}]'
run_reorder left
[[ "$(rename_count)" == "0" ]] || fail "floor: expected no rename"
[[ "$(workspace_name)" == "1" ]] || fail "floor: name unchanged"

# zoom → no rename
write_workspaces '[{"name":"zoom","num":-1,"focused":true}]'
run_reorder left
[[ "$(rename_count)" == "0" ]] || fail "zoom left: expected no rename"
run_reorder right
[[ "$(rename_count)" == "0" ]] || fail "zoom right: expected no rename"

# 9 right, 10 empty → current becomes 10
write_workspaces '[{"name":"9:❾chat","num":9,"focused":true}]'
run_reorder right
[[ "$(workspace_name)" == "10:❿chat" ]] || fail "9 right empty 10"

# 10 right, no 11 → current becomes named
write_workspaces '[{"name":"10:❿chat","num":10,"focused":true}]'
run_reorder right
[[ "$(workspace_name)" == "chat" ]] || fail "10 right: expected chat"
[[ "$(workspace_name)" =~ ^[0-9] ]] && fail "10 right: name must not start with a digit"

# 10 right, 11 exists → 10 becomes named, 11 untouched
write_workspaces '[
  {"name":"10:❿chat","num":10,"focused":true},
  {"name":"11:➕","num":11,"focused":false}
]'
run_reorder right
[[ "$(workspace_name)" == "chat" ]] || fail "10 right with 11: expected chat"
[[ "$(workspace_by_num 11)" == "11:➕" ]] || fail "10 right with 11: 11 untouched"

# named left, 10 empty → current becomes 10
write_workspaces '[{"name":"chat","num":-1,"focused":true}]'
run_reorder left
[[ "$(workspace_name)" == "10:❿chat" ]] || fail "named left empty 10"

# named left, 10 occupied → swap with 10
write_workspaces '[
  {"name":"chat","num":-1,"focused":true},
  {"name":"10:❿news","num":10,"focused":false}
]'
run_reorder left
[[ "$(workspace_name)" == "10:❿chat" ]] || fail "named left swap: chat should be 10"
[[ "$(jq -r '.[] | select(.num == -1).name' "$FAKE_WORKSPACES")" == "news" ]] \
  || fail "named left swap: news should be unnumbered"

# named right → no-op
write_workspaces '[{"name":"chat","num":-1,"focused":true}]'
run_reorder right
[[ "$(rename_count)" == "0" ]] || fail "named right: expected no rename"

# bare 10 right → circled prefix only
write_workspaces '[{"name":"10","num":10,"focused":true}]'
run_reorder right
[[ "$(workspace_name)" == "❿" ]] || fail "bare 10 right: expected ❿"

printf 'i3-reorder-workspace.bash: ok\n'
