#!/usr/bin/env bash

set -e

source_branch=$(git branch --show-current)
target_branch=$1

echo "Merging $source_branch → $target_branch and pushing..."

git pull
git checkout $target_branch
git merge $source_branch
git push

git checkout $source_branch

echo "✔️Done."
