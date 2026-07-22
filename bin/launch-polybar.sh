#!/usr/bin/env bash
set -euo pipefail

if ! command -v polybar >/dev/null 2>&1; then
    echo "launch-polybar: polybar not installed" >&2
    exit 1
fi

killall -q polybar || true
while pgrep -x polybar >/dev/null; do sleep 0.3; done

PRIMARY=$(xrandr --query | awk '/ connected primary/ {print $1}')
if [ -z "$PRIMARY" ]; then
    echo "launch-polybar: no primary xrandr output detected" >&2
    exit 1
fi

MONITOR="$PRIMARY" polybar --reload top >/tmp/polybar-top.log 2>&1 &
MONITOR="$PRIMARY" polybar --reload bottom >/tmp/polybar-bottom.log 2>&1 &

# Any other connected output gets a workspace-only bar.
xrandr --query | awk '/ connected/ && !/ connected primary/ {print $1}' | while read -r OUT; do
    MONITOR="$OUT" polybar --reload top-secondary >"/tmp/polybar-secondary-$OUT.log" 2>&1 &
done
