#!/bin/sh
# spawn-claude DIR [claude-arg ...]
#
# Open a fresh kitty window (i3 adopts it like any other window) whose working
# directory is DIR, running an interactive `claude` session with the given
# arguments. When claude exits, the window drops to an interactive shell in the
# same directory instead of closing, matching a hand-opened terminal.
#
# DIR forms:
#   /abs/path            used as-is
#   ~ or ~/path          expanded against $HOME
#   ./path ../path a/b   used as-is (explicit relative or nested path)
#   bare-name            resolved against ~/projects first, then ~
#                        (so `abstractor` -> ~/projects/abstractor,
#                         `datafold`   -> ~/datafold)
#
# Everything after DIR is forwarded verbatim to claude, e.g.
#   spawn-claude datafold --permission-mode plan "audit the flaky auth test"
#   spawn-claude ~/projects/abstractor --worktree feature-x "add the parser"
set -eu

usage() { echo "usage: spawn-claude DIR [claude-arg ...]" >&2; exit 2; }
[ $# -ge 1 ] || usage
raw=$1
shift

case $raw in
  /*)             dir=$raw ;;
  "~")            dir=$HOME ;;
  "~/"*)          dir=$HOME/${raw#\~/} ;;
  .|..|./*|../*|*/*) dir=$raw ;;
  *)
    if   [ -d "$HOME/projects/$raw" ]; then dir=$HOME/projects/$raw
    elif [ -d "$HOME/$raw" ];          then dir=$HOME/$raw
    else                                    dir=$HOME/projects/$raw
    fi
    ;;
esac

[ -d "$dir" ]                        || { echo "spawn-claude: not a directory: $dir" >&2; exit 1; }
command -v kitty  >/dev/null 2>&1    || { echo "spawn-claude: kitty not found"       >&2; exit 1; }
command -v setsid >/dev/null 2>&1    || { echo "spawn-claude: setsid not found"       >&2; exit 1; }

# Detach fully (new session, closed std streams) so the window outlives the
# caller even when that caller is a short-lived, sandboxed tool invocation.
# claude's arguments ride as the interactive shell's positional parameters, so
# an arbitrary prompt needs no shell re-quoting on the way through.
setsid -f kitty --directory "$dir" \
  zsh -ic 'claude "$@"; exec zsh -i' zsh "$@" \
  >/dev/null 2>&1 </dev/null

echo "spawn-claude: launched claude in $dir"
