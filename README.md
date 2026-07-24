# Anatoly Scherbakov's dotfiles

## Goal

The same Linux workflow problem should rarely happen twice.

This repository turns repeated workstation, development, and agent-workflow
friction into durable configuration, automation, or guidance. Once a problem is
understood, future encounters should be prevented, shortened, or made routine.

## Features

This repo contains my personal settings and configurations for a number of software tools I am regularly using. For example:

* Custom `xkb` setup for Microsoft Natural 4000 keyboard. It helps me typing special characters like ⇔, ∨, ∧, ∪, ∩, ∀, ∃, × and quite a few others.
* Custom `XCompose` setup which allows to input more characters like ⇒, ≠, →, α, ψ.
* Custom key bindings for `i3` window manager which make using it more intuitive for my humble self. Plus, config for IntelliJ IDEA and its sister products to help it work under i3 properly.
* [organize](https://github.com/tfeldmann/organize) configuration to put my stuff into a resemblance of order.
* User-space AI assistant skills, linked into Cursor, Claude Code, and Codex.

Forking this config is pointless because your preferences are going to be very different from mine. But you might be interested to copy-paste something. Enjoy!

## Hardware setup

### SDINNOVATION SIDE-KEYBOARD

To configure the keyboard via its web configurator at https://www.huali-tech.com (WebUSB), the udev rules in `udev/99-sdinnovation-keyboard.rules` must be installed once after a fresh OS installation:

```shell
sudo cp udev/99-sdinnovation-keyboard.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Also ensure your user is in the `plugdev` group (it is by default on Ubuntu).

## systemd OOM policy

Ubuntu monitors the entire `user@.service` for sustained memory pressure.
When `systemd-oomd` selects its `init.scope`, systemd stops the user manager
and every process in the graphical session. The drop-ins in `systemd/` move
pressure monitoring to `app.slice`, where the kill candidate is a descendant
application scope such as a browser.

`./install` links the per-user drop-in. Install the system override for the
current user's service instance, then reload both managers:

```shell
sudo install -D -m 0644 \
  systemd/system/user@.service.d/20-oomd-app-slice.conf \
  "/etc/systemd/system/user@$(id -u).service.d/20-oomd-app-slice.conf"
sudo systemctl daemon-reload
systemctl --user daemon-reload
```

`oomctl dump` should list the user's `app.slice` with a 50% memory-pressure
limit and should not list the enclosing `user@<uid>.service`.

## Prerequisites

```shell script
xargs -a requirements.apt.txt sudo apt install -y
sudo pip3 install -r requirements.txt
```

## Installation

```shell script
./install
```
