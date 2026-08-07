#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_dir/bin/startup.sh"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

fake_home="$temporary/home"
fake_bin="$temporary/bin"
mkdir -p "$fake_home/.config/xkb" "$fake_bin"

cat >"$fake_bin/setxkbmap" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$FAKE_SETXKBMAP_ARGS"
printf 'xkb_keymap { xkb_symbols { include "pc+yeti+ru:2+am(phonetic):3" }; };\n'
EOF

cat >"$fake_bin/xkbcomp" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$FAKE_XKBCOMP_ARGS"
cat >"$FAKE_XKBCOMP_INPUT"
EOF

chmod +x "$fake_bin/setxkbmap" "$fake_bin/xkbcomp"

env \
  HOME="$fake_home" \
  DISPLAY=:42.0 \
  PATH="$fake_bin:$PATH" \
  FAKE_SETXKBMAP_ARGS="$temporary/setxkbmap-args" \
  FAKE_XKBCOMP_ARGS="$temporary/xkbcomp-args" \
  FAKE_XKBCOMP_INPUT="$temporary/xkbcomp-input" \
  bash "$script"

rg -F -- '-layout yeti,ru,am -variant ,,phonetic' "$temporary/setxkbmap-args" >/dev/null
rg -F -- '-option  -option compose:menu -print' "$temporary/setxkbmap-args" >/dev/null
rg -F -- "-I$fake_home/.config/xkb - :42" "$temporary/xkbcomp-args" >/dev/null
rg -F 'pc+yeti+ru:2+am(phonetic):3' "$temporary/xkbcomp-input" >/dev/null
if rg -F '/home/anatoly' "$script" "$repo_dir/bin/i3-resurrect-session.sh" >/dev/null; then
  echo "startup scripts contain a machine-specific home directory" >&2
  exit 1
fi

echo "startup tests passed"
