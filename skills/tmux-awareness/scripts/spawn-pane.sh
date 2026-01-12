#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: spawn-pane.sh [options] -c <command>

Create a new pane in the current window (visible to user).

Options:
  -d, --direction   Split direction: h (horizontal) or v (vertical). Default: h
  -c, --command     Command to run in the pane (required)
  -p, --percent     Pane size as percentage (default: 50)
  -h, --help        Show this help

Output: JSON with pane target for monitoring

Examples:
  spawn-pane.sh -d h -c "claude --print 'Review code'"
  spawn-pane.sh -d v -p 30 -c "npm run watch"
USAGE
}

direction="h"
command=""
percent="50"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--direction) direction="${2:-h}"; shift 2 ;;
    -c|--command)   command="${2:-}"; shift 2 ;;
    -p|--percent)   percent="${2:-50}"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

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
window=$(tmux display-message -p '#{window_index}')

# Create the pane
# -d: don't switch to new pane
# -P: print pane info
# -F: format string
if [[ "$direction" == "h" ]]; then
  pane_info=$(tmux split-window -h -d -p "$percent" -P -F '#{pane_id}:#{pane_index}' "$command")
else
  pane_info=$(tmux split-window -v -d -p "$percent" -P -F '#{pane_id}:#{pane_index}' "$command")
fi

pane_id=$(echo "$pane_info" | cut -d: -f1)
pane_index=$(echo "$pane_info" | cut -d: -f2)
target="$session:$window.$pane_index"

cat <<EOF
{
  "success": true,
  "pane_id": "$pane_id",
  "pane_index": $pane_index,
  "target": "$target",
  "command": $(printf '%s' "$command" | jq -Rs .)
}
EOF
