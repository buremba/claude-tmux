#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: capture-output.sh [options] [-t <target>]

Capture recent output from a tmux pane.

Options:
  -t, --target    Tmux target (session:window.pane). Default: current pane
  -l, --lines     Number of lines to capture (default: 100)
  -j, --json      Output as JSON with metadata
  -h, --help      Show this help

Examples:
  capture-output.sh -t "dev-server:0.0" -l 50
  capture-output.sh -t "agent-1:0.0" --json
USAGE
}

target=""
lines=100
json_output=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) target="${2:-}"; shift 2 ;;
    -l|--lines)  lines="${2:-100}"; shift 2 ;;
    -j|--json)   json_output=true; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# Verify we're in tmux
if ! tmux display-message -p '#{session_name}' >/dev/null 2>&1; then
  echo "Error: Not running inside tmux" >&2
  exit 1
fi

# Default to current pane if no target specified
if [[ -z "$target" ]]; then
  session=$(tmux display-message -p '#{session_name}')
  window=$(tmux display-message -p '#{window_index}')
  pane=$(tmux display-message -p '#{pane_index}')
  target="$session:$window.$pane"
fi

# Capture the pane contents
# -p: print to stdout
# -J: join wrapped lines
# -S: start line (negative = from end)
output=$(tmux capture-pane -p -J -t "$target" -S "-${lines}" 2>&1) || {
  if [[ "$json_output" == "true" ]]; then
    echo '{"error": "Failed to capture pane", "target": "'"$target"'"}'
  else
    echo "Error: Failed to capture pane $target" >&2
  fi
  exit 1
}

if [[ "$json_output" == "true" ]]; then
  cat <<EOF
{
  "target": "$target",
  "lines": $lines,
  "output": $(printf '%s' "$output" | jq -Rs .)
}
EOF
else
  printf '%s\n' "$output"
fi
