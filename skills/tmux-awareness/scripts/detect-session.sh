#!/usr/bin/env bash
set -euo pipefail

# Detect current tmux session and return JSON info
# Returns: {"in_tmux": true/false, "session": "name", "window": N, "pane": N, "target": "session:window.pane"}

# Check if tmux commands work (indicates we're in tmux)
if ! tmux display-message -p '#{session_name}' >/dev/null 2>&1; then
  echo '{"in_tmux": false}'
  exit 0
fi

session=$(tmux display-message -p '#{session_name}')
window=$(tmux display-message -p '#{window_index}')
pane=$(tmux display-message -p '#{pane_index}')
pane_id=$(tmux display-message -p '#{pane_id}')
window_name=$(tmux display-message -p '#{window_name}')

cat <<EOF
{
  "in_tmux": true,
  "session": "$session",
  "window": $window,
  "window_name": "$window_name",
  "pane": $pane,
  "pane_id": "$pane_id",
  "target": "$session:$window.$pane"
}
EOF
