#!/usr/bin/env bash

set -Eeuo pipefail

if ! command -v chromium >/dev/null 2>&1; then
    echo "playwright-chromium: chromium is not installed" >&2
    exit 1
fi

port=${PLAYWRIGHT_CDP_PORT:-9223}
runtime_dir=${XDG_RUNTIME_DIR:-/tmp}
chromium_path=$(command -v chromium)

if [[ $chromium_path == /snap/bin/* ]]; then
    default_profile_dir="$HOME/snap/chromium/common/playwright-chromium"
else
    default_profile_dir="$runtime_dir/playwright-chromium"
fi

profile_dir=${PLAYWRIGHT_CHROMIUM_PROFILE:-$default_profile_dir}
mkdir -p "$profile_dir"

echo "Starting Chromium for Playwright at http://127.0.0.1:$port"

exec chromium \
    --remote-debugging-address=127.0.0.1 \
    --remote-debugging-port="$port" \
    --user-data-dir="$profile_dir" \
    --no-first-run \
    --no-default-browser-check \
    "$@"
