#!/usr/bin/env bash
# Generate demo cast files for all use cases
# This script creates asciinema recordings showing the tmux plugin in action

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORD_SCRIPT="$PLUGIN_DIR/skills/record/skill.sh"
RECORDINGS_DIR="$PLUGIN_DIR/skills/record/recordings"
DEMO_WIDTH=120
DEMO_HEIGHT=35
DEMO_TIMEOUT=120

# Check if record script exists
if [ ! -f "$RECORD_SCRIPT" ]; then
    echo -e "${RED}Error: Record script not found at $RECORD_SCRIPT${NC}"
    exit 1
fi

# Create recordings directory if it doesn't exist
mkdir -p "$RECORDINGS_DIR"

# Function to record a demo
record_demo() {
    local name="$1"
    local prompt="$2"
    local output_file="$RECORDINGS_DIR/demo-${name}.cast"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Recording: ${name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Prompt: $prompt"
    echo "Output: $output_file"
    echo ""

    if "$RECORD_SCRIPT" \
        -p "$prompt" \
        -o "$output_file" \
        -w "$DEMO_WIDTH" \
        -h "$DEMO_HEIGHT" \
        -t "$DEMO_TIMEOUT"; then
        echo -e "${GREEN}✓ Successfully recorded: $name${NC}"
        echo "  File: $output_file"
        ls -lh "$output_file"
    else
        echo -e "${RED}✗ Failed to record: $name${NC}"
        return 1
    fi
    echo ""
}

# Main menu
show_menu() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Claude Tmux Plugin - Demo Generation               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Select demos to generate:"
    echo ""
    echo "  1) All demos"
    echo "  2) Detect tmux session"
    echo "  3) Spawn visible pane"
    echo "  4) Spawn background window"
    echo "  5) Wait for pattern (server ready)"
    echo "  6) Capture output from pane"
    echo "  7) Queue message for next session"
    echo "  8) Combined workflow (pane + window)"
    echo ""
    echo "  q) Quit"
    echo ""
}

# Demo definitions
demos_detect_session() {
    record_demo "detect-session" \
        "Use the detect-session.sh script to check if we're in tmux and get session info"
}

demos_spawn_pane() {
    record_demo "spawn-pane" \
        "Spawn a visible split pane using spawn-pane.sh with a command like 'echo Hello from parallel pane'"
}

demos_spawn_window() {
    record_demo "spawn-window" \
        "Create a background window using spawn-window.sh named 'demo-server' with 'python3 -m http.server 8765'"
}

demos_wait_for_text() {
    record_demo "wait-for-text" \
        "Start a simple server in background and use wait-for-text.sh to wait for the 'Serving HTTP' message with a 30 second timeout"
}

demos_capture_output() {
    record_demo "capture-output" \
        "Use capture-output.sh to capture the last 20 lines from a pane and display them with JSON formatting"
}

demos_queue_message() {
    record_demo "queue-message" \
        "Use queue-message.sh to queue a message like 'Remember to review the PR when you start the next session'"
}

demos_combined_workflow() {
    record_demo "combined-workflow" \
        "Demonstrate a complete workflow: spawn a background window with a dev server, spawn a visible pane to show logs, wait for server ready, and queue a follow-up message"
}

demos_all() {
    echo -e "${YELLOW}Generating all demos...${NC}"
    echo ""
    demos_detect_session
    sleep 2
    demos_spawn_pane
    sleep 2
    demos_spawn_window
    sleep 2
    demos_wait_for_text
    sleep 2
    demos_capture_output
    sleep 2
    demos_queue_message
    sleep 2
    demos_combined_workflow
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Enter your choice: " choice

        case "$choice" in
            1)
                demos_all
                ;;
            2)
                demos_detect_session
                ;;
            3)
                demos_spawn_pane
                ;;
            4)
                demos_spawn_window
                ;;
            5)
                demos_wait_for_text
                ;;
            6)
                demos_capture_output
                ;;
            7)
                demos_queue_message
                ;;
            8)
                demos_combined_workflow
                ;;
            q|Q)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                echo ""
                ;;
        esac
    done
}

# Run main function
main
