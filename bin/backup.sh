#!/usr/bin/env bash

set -uo pipefail

STATE_DIRECTORY="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_FILE="$STATE_DIRECTORY/backup.log"
LOCK_FILE="$STATE_DIRECTORY/backup.lock"
REPOSITORY="$HOME/projects/dotfiles"
PYTHON="$HOME/Documents/.venv/bin/python"

mkdir -p "$STATE_DIRECTORY"
exec 9>"$LOCK_FILE"

if ! flock -n 9; then
    printf '%s BACKUP SKIPPED: another backup is running\n' "$(date --iso-8601=seconds)" >> "$LOG_FILE"
    exit 0
fi

exec >> "$LOG_FILE" 2>&1

started_at=$(date +%s)
printf '\n%s BACKUP START\n' "$(date --iso-8601=seconds)"

finish() {
    local result="$1"
    local exit_code="$2"
    local elapsed=$(( $(date +%s) - started_at ))

    printf '%s BACKUP %s exit=%s duration=%02dh:%02dm:%02ds\n' \
        "$(date --iso-8601=seconds)" "$result" "$exit_code" \
        $(( elapsed / 3600 )) $(( (elapsed % 3600) / 60 )) $(( elapsed % 60 ))
    exit "$exit_code"
}

cd "$REPOSITORY" || finish FAILED 1

if ! timeout --foreground --kill-after=5s 15s "$PYTHON" -c 'import jeeves; jeeves.healthcheck()'; then
    finish FAILED 1
fi

if "$PYTHON" -c 'import jeeves; jeeves.sync()'; then
    finish SUCCESS 0
fi

finish FAILED 1
