#!/usr/bin/env bash
# Mount Synology NAS using sshfs

set -e

MOUNT_POINT="$HOME/synology"

# Create mount point if it doesn't exist
mkdir -p "$MOUNT_POINT"

# Mount Synology
sshfs synology.local:/ ~/synology -o idmap=user
