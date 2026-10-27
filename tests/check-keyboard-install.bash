#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/bin/check-keyboard-install.sh"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

pairs=(
  "xkb/yeti:/usr/share/X11/xkb/symbols/yeti"
  "xkb/90-yeti-keyboard.conf:/etc/X11/xorg.conf.d/90-yeti-keyboard.conf"
  "udev/70-sdinnovation-keyboard.rules:/etc/udev/rules.d/70-sdinnovation-keyboard.rules"
)

for pair in "${pairs[@]}"; do
  rg -F -- "${pair%%:*}" "$repo_dir/install.keyboard.conf.yaml" >/dev/null
  rg -F -- "${pair#*:}" "$repo_dir/install.keyboard.conf.yaml" >/dev/null
  rg -F -- "$pair" "$script" >/dev/null
  install -D -m 0644 "$repo_dir/${pair%%:*}" "$temporary${pair#*:}"
done

check() {
  KEYBOARD_SYSTEM_ROOT="$temporary" bash "$script"
}

output="$(check)"
if [[ -n "$output" ]]; then
  echo "unexpected output when all files match: $output" >&2
  exit 1
fi

echo changed >>"$temporary/etc/X11/xorg.conf.d/90-yeti-keyboard.conf"
output="$(check)"
rg -F "Outdated: $temporary/etc/X11/xorg.conf.d/90-yeti-keyboard.conf" <<<"$output" >/dev/null
rg -F 'Run ./install-keyboard' <<<"$output" >/dev/null

rm "$temporary/usr/share/X11/xkb/symbols/yeti"
output="$(check)"
rg -F "Missing: $temporary/usr/share/X11/xkb/symbols/yeti" <<<"$output" >/dev/null

echo "check-keyboard-install tests passed"
