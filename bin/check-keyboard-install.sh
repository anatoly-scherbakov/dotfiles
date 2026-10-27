#!/usr/bin/env bash
# Report system copies that `./install-keyboard` installed and that no longer
# match the repository. Exits 0 so that a stale copy does not stop `./install`.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
system_root="${KEYBOARD_SYSTEM_ROOT:-}"

pairs=(
  "xkb/yeti:/usr/share/X11/xkb/symbols/yeti"
  "xkb/90-yeti-keyboard.conf:/etc/X11/xorg.conf.d/90-yeti-keyboard.conf"
  "udev/70-sdinnovation-keyboard.rules:/etc/udev/rules.d/70-sdinnovation-keyboard.rules"
)

stale=0
for pair in "${pairs[@]}"; do
  source="$repo_dir/${pair%%:*}"
  destination="$system_root${pair#*:}"
  if [[ ! -e "$destination" ]]; then
    echo "Missing: $destination"
    stale=1
  elif ! cmp -s "$source" "$destination"; then
    echo "Outdated: $destination differs from ${pair%%:*}"
    stale=1
  fi
done

if (( stale )); then
  echo "Run ./install-keyboard to update the system keyboard files."
fi
