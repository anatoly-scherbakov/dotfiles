#!/usr/bin/env bash
# i3 RENamEr
# Usage:
#
#    irene boo
#
# If your workspace was previously called, say, 5:abc, after this call it will
# be renamed to 5:boo.
#
# Your number-based keyboard shortcuts will be preserved.

title=$1
num=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).num')

desired_name="\"$num:$title\""

current_name=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name')
i3-msg rename workspace "$current_name" to "$desired_name"
