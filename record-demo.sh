#!/usr/bin/env bash
# Simple script to record individual demos
# Usage: ./record-demo.sh <demo-name>

set -eo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORD_SCRIPT="$PLUGIN_DIR/skills/record/skill.sh"
RECORDINGS_DIR="$PLUGIN_DIR/skills/record/recordings"

mkdir -p "$RECORDINGS_DIR"

# Get prompt for demo name
get_prompt() {
    case "$1" in
        detect-session)
            echo "Use the detect-session.sh script to check if we're in tmux and get session info"
            ;;
        spawn-pane)
            echo "Spawn a visible split pane using spawn-pane.sh with a command like 'echo Hello from parallel pane'"
            ;;
        spawn-window)
            echo "Create a background window using spawn-window.sh named 'demo-server' with 'python3 -m http.server 8765'"
            ;;
        wait-for-text)
            echo "Start a simple server in background and use wait-for-text.sh to wait for the 'Serving HTTP' message"
            ;;
        capture-output)
            echo "Use capture-output.sh to capture the last 20 lines from a pane and display them"
            ;;
        queue-message)
            echo "Use queue-message.sh to queue a message like 'Remember to check the tests'"
            ;;
        combined-workflow)
            echo "Demonstrate a complete workflow: background window with server, visible pane with logs, wait for ready"
            ;;
        *)
            return 1
            ;;
    esac
}

usage() {
    echo "Usage: $0 <demo-name>"
    echo ""
    echo "Available demos:"
    echo "  - detect-session"
    echo "  - spawn-pane"
    echo "  - spawn-window"
    echo "  - wait-for-text"
    echo "  - capture-output"
    echo "  - queue-message"
    echo "  - combined-workflow"
    echo ""
    echo "Example: $0 detect-session"
}

if [ $# -eq 0 ]; then
    usage
    exit 0
fi

DEMO_NAME="$1"

PROMPT=$(get_prompt "$DEMO_NAME" 2>/dev/null) || {
    echo "Error: Unknown demo '$DEMO_NAME'"
    echo ""
    usage
    exit 1
}
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
