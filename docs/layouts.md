---
title: Switch keyboard layouts with Caps Lock
---

add to `~/.profile`:

```shell
setxkbmap -symbols yeti -print | xkbcomp -I"$HOME/.config/xkb" - "${DISPLAY%%.*}"
```
