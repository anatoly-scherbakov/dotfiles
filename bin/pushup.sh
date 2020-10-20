#!/usr/bin/env bash

set -e

source_branch=$(git branch --show-current)

git push --set-upstream origin $source_branch

echo "✔ ️Done."
