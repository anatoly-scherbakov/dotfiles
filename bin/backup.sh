#!/usr/bin/env bash

# Stop if ~/synology is empty (not mounted)
if [ -z "$(ls -A ~/synology 2>/dev/null)" ]; then
    echo "Error: ~/synology is empty or not mounted"
    exit 1
fi

excludes="--exclude=.git \
--exclude=.DS_Store \
--exclude=.idea \
--exclude=.vscode \
--exclude=.env \
--exclude=.env.* \
--exclude=.mypy_cache \
--exclude=.pytest_cache \
--exclude=__pycache__ \
--exclude=.ruff_cache \
--exclude=.fingerprint \
--exclude=*.pyc \
--exclude=node_modules \
--exclude=mkdocs-material-insiders \
--exclude=.venv"

options="-avJ --progress --delete --no-group"

rsync $options $excludes ~/projects/ ~/synology/home/projects/
rsync $options $excludes ~/Documents/ ~/synology/home/Documents/
