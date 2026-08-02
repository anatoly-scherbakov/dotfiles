#!/usr/bin/env bash

set -Eeuo pipefail

if ! command -v chromium >/dev/null 2>&1; then
    echo "playwright-chromium: chromium is not installed" >&2
    exit 1
fi

port=${PLAYWRIGHT_CDP_PORT:-9223}
runtime_dir=${XDG_RUNTIME_DIR:-/tmp}
profile_dir=${PLAYWRIGHT_CHROMIUM_PROFILE:-$runtime_dir/playwright-chromium}

echo "Starting Chromium for Playwright at http://127.0.0.1:$port"

exec chromium \
    --remote-debugging-address=127.0.0.1 \
    --remote-debugging-port="$port" \
    --user-data-dir="$profile_dir" \
    --no-first-run \
    --no-default-browser-check \
    "$@"
