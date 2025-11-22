#!/usr/bin/env bash
# Mount Synology NAS using sshfs

set -e

MOUNT_POINT="$HOME/synology"

# Create mount point if it doesn't exist
mkdir -p "$MOUNT_POINT"

# Mount Synology
echo "$SYNOLOGY_PASSWORD" | sshfs -o password_stdin synology.local:/ ~/synology -o idmap=user
