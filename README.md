# Anatoly Scherbakov's dotfiles


## Features

This repo contains my personal settings and configurations for a number of software tools I am regularly using. For example:

* Custom `xkb` setup for Microsoft Natural 4000 keyboard. It helps me typing special characters like ⇔, ∨, ∧, ∪, ∩, ∀, ∃, × and quite a few others.
* Custom `XCompose` setup which allows to input more characters like ⇒, ≠, →, α, ψ.
* Custom key bindings for `i3` window manager which make using it more intuitive for my humble self. Plus, config for IntelliJ IDEA and its sister products to help it work under i3 properly.
* [organize](https://github.com/tfeldmann/organize) configuration to put my stuff into a resemblance of order.

Forking this config is pointless because your preferences are going to be very different from mine. But you might be interested to copy-paste something. Enjoy!

## Hardware setup

### SDINNOVATION SIDE-KEYBOARD

To configure the keyboard via its web configurator at https://www.huali-tech.com (WebUSB), the udev rules in `udev/99-sdinnovation-keyboard.rules` must be installed once after a fresh OS installation:

```shell
sudo cp udev/99-sdinnovation-keyboard.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Also ensure your user is in the `plugdev` group (it is by default on Ubuntu).

## Prerequisites

```shell script
sudo pip3 install -r requirements.txt
```

## Installation

```shell script
./install
```
