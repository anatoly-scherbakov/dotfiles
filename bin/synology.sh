#!/usr/bin/env bash
# Mount Synology NAS using sshfs

set -euo pipefail

MOUNT_POINT="$HOME/synology"
REMOTE="${SYNOLOGY_REMOTE:-synology.local:/}"

mkdir -p "$MOUNT_POINT"

if mountpoint -q "$MOUNT_POINT"; then
    echo "$MOUNT_POINT is already mounted"
    exit 0
fi

if [[ -z "${SYNOLOGY_PASSWORD:-}" ]]; then
    if TTY=$(tty 2>/dev/null); then
        printf "Synology password: " > "$TTY"
        IFS= read -rs SYNOLOGY_PASSWORD < "$TTY"
        printf "\n" > "$TTY"
    else
        echo "Error: SYNOLOGY_PASSWORD is not set and no terminal is available for prompting" >&2
        exit 1
    fi
fi

printf "%s\n" "$SYNOLOGY_PASSWORD" | sshfs -o password_stdin "$REMOTE" "$MOUNT_POINT" -o idmap=user
