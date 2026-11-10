#!/usr/bin/env bash
set -euo pipefail

setxkbmap -layout yeti,ru,am -variant ,,phonetic -option '' -option compose:ins \
  -print | xkbcomp -I"$HOME/.config/xkb" - "${DISPLAY%%.*}"

# Defense in depth against session environments that route input through IBus
# (see ~/.xinputrc, im-config).  IBus's default xkb engines never read
# ~/.XCompose, so with IBus in the way, custom Compose sequences are dead.
# Toolkits' built-in input contexts honor ~/.XCompose directly.
unset GTK_IM_MODULE QT_IM_MODULE XMODIFIERS
