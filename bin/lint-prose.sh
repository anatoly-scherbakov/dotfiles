#!/usr/bin/env bash
set -euo pipefail

script_path=$(readlink -f "${BASH_SOURCE[0]}")
repository_root=$(cd "$(dirname "$script_path")/.." && pwd)

exec vale --no-global --config="$repository_root/vale/vale.ini" --ext=.md "$@"
