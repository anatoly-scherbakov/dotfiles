#!/usr/bin/env bash
# Bubble the focused workspace number left or right (1-10). Past 10 it
# drops the i3 number. Usage: i3-reorder-workspace left|right

set -euo pipefail

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=i3-workspace-name.sh
source "$script_dir/i3-workspace-name.sh"

direction="${1:-}"
if [[ "$direction" != "left" && "$direction" != "right" ]]; then
  printf 'usage: %s left|right\n' "$(basename "$0")" >&2
  exit 1
fi

rename_workspace() {
  i3-msg rename workspace "$1" to "$2" >/dev/null
}

workspaces_json="$(i3-msg -t get_workspaces)"
focused="$(jq -c '.[] | select(.focused==true)' <<<"$workspaces_json")"
[[ -n "$focused" && "$focused" != "null" ]] || exit 0

name="$(jq -r '.name' <<<"$focused")"
num="$(jq -r '.num' <<<"$focused")"

if [[ "$name" == "zoom" ]]; then
  exit 0
fi

title="$(i3_workspace_title "$name" "$num")"
target=""

if [[ "$direction" == "left" ]]; then
  if [[ "$num" == "-1" ]]; then
    target=10
  elif ((num <= 1)); then
    exit 0
  else
    target=$((num - 1))
  fi
else
  if [[ "$num" == "-1" ]]; then
    exit 0
  elif ((num >= 10)); then
    new_name="$(i3_workspace_unnumbered_name "$name" "$num")"
    if [[ "$new_name" == "$name" ]]; then
      exit 0
    fi
    rename_workspace "$name" "$new_name"
    exit 0
  else
    target=$((num + 1))
  fi
fi

occupant="$(jq -c --argjson n "$target" '.[] | select(.num == $n)' <<<"$workspaces_json")"
if [[ -z "$occupant" ]]; then
  rename_workspace "$name" "$(i3_workspace_numbered_name "$target" "$title")"
  exit 0
fi

occ_name="$(jq -r '.name' <<<"$occupant")"
occ_num="$(jq -r '.num' <<<"$occupant")"
occ_title="$(i3_workspace_title "$occ_name" "$occ_num")"
# i3 refuses to rename to a name starting with "__" (reserved as
# i3-internal), and parses a leading digit as the workspace number, so the
# scratch name uses a non-numeric, non-underscore prefix.
tmp="i3-reorder-tmp-$$"

if [[ "$num" == "-1" ]]; then
  rename_workspace "$name" "$tmp"
  rename_workspace "$occ_name" "$(i3_workspace_unnumbered_name "$occ_name" "$occ_num")"
  rename_workspace "$tmp" "$(i3_workspace_numbered_name "$target" "$title")"
  exit 0
fi

rename_workspace "$name" "$tmp"
rename_workspace "$occ_name" "$(i3_workspace_numbered_name "$num" "$occ_title")"
rename_workspace "$tmp" "$(i3_workspace_numbered_name "$target" "$title")"
