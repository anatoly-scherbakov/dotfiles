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
  # Named workspace (no numeric id): keep current name as prefix
  desired_name="${current_name}: ${title}"
else
  case "$num" in
    11) desired_name="11: ➕ ${title}" ;;
    12) desired_name="12: ➖ ${title}" ;;
    13) desired_name="13: ✖ ${title}" ;;
    14) desired_name="14: ➗ ${title}" ;;
    *)  desired_name="${num}: ${title}" ;;
  esac
fi

i3-msg rename workspace "$current_name" to "$desired_name"
