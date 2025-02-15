#!/bin/bash

# Check if any window is marked "AI"
if ! i3-msg -t get_tree | jq -e '.. | objects | select(.marks | index("AI"))' > /dev/null; then
    exit 1  # No AI window found, exit the script
fi

# Copy primary selection to clipboard
xclip -o -selection primary | xclip -selection clipboard

# Focus the ChatGPT window
i3-msg '[con_mark=AI] focus'

# Wait for the window to be ready
sleep 0.5

# Open the input box (Shift+Escape in ChatGPT web)
xdotool key Shift+Escape

# Wait for input mode activation
sleep 0.5

# Paste clipboard contents
xdotool key ctrl+v
