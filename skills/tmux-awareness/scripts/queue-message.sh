#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: queue-message.sh <message>
       echo "message" | queue-message.sh -

Queue a message for the next Claude session (self-continuation).

Options:
  -h, --help    Show this help

The message will be delivered when a new Claude session starts.

Examples:
  queue-message.sh "Remember to check test results"
  echo "Follow up on PR review" | queue-message.sh -
USAGE
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

# Read message from stdin if "-" is passed, otherwise use arguments
if [[ "$1" == "-" ]]; then
  message=$(cat)
else
  message="$*"
fi

if [[ -z "$message" ]]; then
  echo "Error: Message cannot be empty" >&2
  exit 1
fi

# Create messages directory if needed
MSG_DIR="${HOME}/.claude/tmux-messages"
mkdir -p "$MSG_DIR"

# Generate filename with timestamp and random suffix for ordering
timestamp=$(date +%s)
random=$(head -c 4 /dev/urandom | xxd -p)
filename="${timestamp}-${random}.md"
filepath="$MSG_DIR/$filename"

# Write the message
printf '%s\n' "$message" > "$filepath"

echo '{"success": true, "file": "'"$filepath"'", "message": "Message queued for next session"}'
