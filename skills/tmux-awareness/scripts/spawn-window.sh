#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: spawn-window.sh [options] -n <name> -c <command>

Create a new window for background workers (separate from current view).

Options:
  -n, --name      Window name (required)
  -c, --command   Command to run (required)
  -s, --switch    Switch to the new window (default: false, stays in current)
  -h, --help      Show this help

Output: JSON with window target for monitoring

Examples:
  spawn-window.sh -n "dev-server" -c "npm run dev"
  spawn-window.sh -n "agent-1" -c "claude --print 'Fix bug'" --switch
USAGE
}

name=""
command=""
switch=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)    name="${2:-}"; shift 2 ;;
    -c|--command) command="${2:-}"; shift 2 ;;
    -s|--switch)  switch=true; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$name" ]]; then
  echo "Error: --name is required" >&2
  usage
  exit 1
fi

if [[ -z "$command" ]]; then
  echo "Error: --command is required" >&2
  usage
  exit 1
fi

# Verify we're in tmux
if ! tmux display-message -p '#{session_name}' >/dev/null 2>&1; then
  echo '{"error": "Not running inside tmux"}' >&2
  exit 1
fi

session=$(tmux display-message -p '#{session_name}')

# Create the window
# -d: don't switch to new window (unless --switch)
# -n: window name
# -P: print window info
# -F: format string
tmux_args=(-n "$name" -P -F '#{window_id}:#{window_index}')

if [[ "$switch" == "false" ]]; then
  tmux_args=(-d "${tmux_args[@]}")
fi

window_info=$(tmux new-window "${tmux_args[@]}" "$command")

window_id=$(echo "$window_info" | cut -d: -f1)
window_index=$(echo "$window_info" | cut -d: -f2)
target="$session:$window_index.0"

cat <<EOF
{
  "success": true,
  "window_id": "$window_id",
  "window_index": $window_index,
  "window_name": "$name",
  "target": "$target",
  "command": $(printf '%s' "$command" | jq -Rs .),
  "switched": $switch
}
EOF
