#!/usr/bin/env bash
# Simple script to record individual demos
# Usage: ./record-demo.sh <demo-name>

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORD_SCRIPT="$PLUGIN_DIR/skills/record/skill.sh"
RECORDINGS_DIR="$PLUGIN_DIR/skills/record/recordings"

mkdir -p "$RECORDINGS_DIR"

# Demo definitions: name => prompt
declare -A DEMOS=(
    ["detect-session"]="Use the detect-session.sh script to check if we're in tmux and get session info"
    ["spawn-pane"]="Spawn a visible split pane using spawn-pane.sh with a command like 'echo Hello from parallel pane'"
    ["spawn-window"]="Create a background window using spawn-window.sh named 'demo-server' with 'python3 -m http.server 8765'"
    ["wait-for-text"]="Start a simple server in background and use wait-for-text.sh to wait for the 'Serving HTTP' message"
    ["capture-output"]="Use capture-output.sh to capture the last 20 lines from a pane and display them"
    ["queue-message"]="Use queue-message.sh to queue a message like 'Remember to check the tests'"
    ["combined-workflow"]="Demonstrate a complete workflow: background window with server, visible pane with logs, wait for ready"
)

usage() {
    echo "Usage: $0 <demo-name>"
    echo ""
    echo "Available demos:"
    for name in "${!DEMOS[@]}"; do
        echo "  - $name"
    done | sort
    echo ""
    echo "Example: $0 detect-session"
}

if [ $# -eq 0 ]; then
    usage
    exit 0
fi

DEMO_NAME="$1"

if [ -z "${DEMOS[$DEMO_NAME]:-}" ]; then
    echo "Error: Unknown demo '$DEMO_NAME'"
    echo ""
    usage
    exit 1
fi

PROMPT="${DEMOS[$DEMO_NAME]}"
OUTPUT_FILE="$RECORDINGS_DIR/demo-${DEMO_NAME}.cast"

echo "Recording demo: $DEMO_NAME"
echo "Prompt: $PROMPT"
echo "Output: $OUTPUT_FILE"
echo ""

if "$RECORD_SCRIPT" \
    -p "$PROMPT" \
    -o "$OUTPUT_FILE" \
    -w 120 \
    -h 35 \
    -t 120; then
    echo ""
    echo "✓ Successfully recorded: $DEMO_NAME"
    echo "  File: $OUTPUT_FILE"
    ls -lh "$OUTPUT_FILE"
    echo ""
    echo "To play: asciinema play '$OUTPUT_FILE'"
    echo "To upload: asciinema upload '$OUTPUT_FILE'"
else
    echo ""
    echo "✗ Failed to record demo"
    exit 1
fi
