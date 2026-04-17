#!/usr/bin/env bash
set -e

setxkbmap -layout yeti,ru,am -variant ,,phonetic -option '' -option compose:menu \
  -print | xkbcomp -I"$HOME/.config/xkb" - "${DISPLAY%%.*}"
