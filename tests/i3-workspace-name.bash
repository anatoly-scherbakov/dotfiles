#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper="$repo_dir/bin/i3-workspace-name.sh"

# shellcheck source=../bin/i3-workspace-name.sh
source "$helper"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local got="$1" expected="$2" label="$3"
  [[ "$got" == "$expected" ]] || fail "$label: got '$got' expected '$expected'"
}

assert_eq "$(i3_workspace_numbered_name 3 chat)" "3:❸chat" "numbered 3"
assert_eq "$(i3_workspace_numbered_name 10 chat)" "10:❿chat" "numbered 10"
assert_eq "$(i3_workspace_numbered_name 11 foo)" "11:➕foo" "numbered 11"
assert_eq "$(i3_workspace_numbered_name 3 "")" "3:❸" "numbered 3 empty title"

assert_eq "$(i3_workspace_title "3:❸chat" 3)" "chat" "title irene 3"
assert_eq "$(i3_workspace_title "3" 3)" "" "title bare 3"
assert_eq "$(i3_workspace_title "10:❿chat" 10)" "chat" "title irene 10"
assert_eq "$(i3_workspace_title "chat" -1)" "chat" "title named"

assert_eq "$(i3_workspace_unnumbered_name "10:❿chat" 10)" "chat" "unnumber titled"
assert_eq "$(i3_workspace_unnumbered_name "10" 10)" "❿" "unnumber bare 10"
assert_eq "$(i3_workspace_unnumbered_name "9:❾chat" 9)" "chat" "unnumber 9"

printf 'i3-workspace-name.bash: ok\n'
