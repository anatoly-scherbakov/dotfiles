#!/usr/bin/env bash

set -euo pipefail

PATH="$HOME/.local/bin:$PATH"

ip_address=${REMARKABLE_IP:-10.11.99.1}
mountpoint=${REMARKABLE_MOUNTPOINT:-$HOME/reMarkable}
package=remarkable-usb-web-interface-fuse
command_name=rmuwifuse

if ! command -v uv >/dev/null 2>&1; then
    echo "uv is required but was not found on PATH" >&2
    exit 1
fi

if [ ! -e /dev/fuse ]; then
    echo "/dev/fuse is missing. Load FUSE first, e.g.: sudo modprobe fuse" >&2
    exit 1
fi

uv tool install --upgrade "$package"

mkdir -p "$mountpoint"

if mountpoint -q "$mountpoint"; then
    echo "$mountpoint is already mounted; unmounting it first"
    fusermount -u "$mountpoint" || fusermount3 -u "$mountpoint"
fi

echo "Mounting reMarkable USB web interface at $mountpoint"
exec "$command_name" "$ip_address" "$mountpoint"
