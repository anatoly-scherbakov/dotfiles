#!/usr/bin/env bash
# i3 RENamEr
# Usage:
#
#    irene boo
#
# Numeric workspaces (1-10, 11-14): renamed to num:boo so keybindings still work.
# Workspaces 11-14 (numpad ➕➖✖➗) use num:emoji title so the bar shows "emoji title".

title=$1
num=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).num')
current_name=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).name')

if [[ "$num" == "-1" || -z "$num" ]]; then
  # Named workspace (no numeric id)
  # Special case: never rename the dedicated "zoom" workspace.
  if [[ "$current_name" == "zoom" ]]; then
    exit 0
  fi

  # Default: keep current name as prefix
  desired_name="${current_name}: ${title}"
else
  # Symbol prefixes for workspaces 0–14. Index is the workspace num.
  prefixes=("🄌" "❶" "❷" "❸" "❹" "❺" "❻" "❼" "❽" "❾" "❿" "➕" "➖" "✖" "➗")
  prefix="${prefixes[$num]}"

  if [[ -n "$prefix" ]]; then
    # Keep numeric prefix so `workspace number N` continues to target this
    # workspace; i3bar (with strip_workspace_numbers yes) will hide "N:"
    # and only show the symbol+title like `❶foo` or `➕bar`.
    desired_name="${num}:${prefix}${title}"
  else
    # Fallback: numeric prefix plus raw title
    desired_name="${num}: ${title}"
  fi
fi

i3-msg rename workspace "$current_name" to "$desired_name"
