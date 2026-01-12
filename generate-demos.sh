#!/usr/bin/env bash
# Generate all demo cast files for the docs page
# Run this from inside a tmux session with Claude CLI available

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/docs"
RECORD_SCRIPT="$SCRIPT_DIR/skills/record/scripts/record.sh"

# Check prerequisites
check_prereqs() {
    if [ -z "${TMUX:-}" ]; then
        echo "Error: Must run inside tmux session"
        echo "Start tmux first: tmux new -s demos"
        exit 1
    fi

    if ! command -v claude &>/dev/null; then
        echo "Error: Claude CLI not found"
        exit 1
    fi

    if ! command -v asciinema &>/dev/null; then
        echo "Error: asciinema not found (brew install asciinema)"
        exit 1
    fi

    if [ ! -f "$RECORD_SCRIPT" ]; then
        echo "Error: Record script not found at $RECORD_SCRIPT"
        exit 1
    fi
}

record_demo() {
    local name="$1"
    local prompt="$2"
    local output="$DOCS_DIR/${name}.cast"

    echo ""
    echo "========================================"
    echo "Recording: $name"
    echo "Output: $output"
    echo "========================================"
    echo ""

    "$RECORD_SCRIPT" -p "$prompt" -o "$output" -w 100 -h 30 -t 180

    if [ -f "$output" ]; then
        echo "Success: $output created"
    else
        echo "Warning: $output not created"
    fi
}

main() {
    check_prereqs

    echo "Generating demo cast files for claude-tmux"
    echo "This will record 4 demos sequentially"
    echo ""

    # Demo 1: Dev Server + Logs
    record_demo "devserver" \
        "Start a simple HTTP server (python3 -m http.server 8080) in a background tmux window named 'server'. Then create a visible pane showing the server logs. Wait until you see 'Serving HTTP' in the output, then report that the server is ready."

    # Demo 2: Parallel Bug Fixes
    record_demo "parallel" \
        "I need to fix 3 issues in parallel. Spawn 3 separate Claude agents in background tmux windows: one to add a TODO comment to any Python file, one to add a TODO comment to any shell script, and one to list the current directory. Report when all 3 are done."

    # Demo 3: Tests + Self-Continuation
    record_demo "tests" \
        "Run 'echo Running tests... && sleep 2 && echo All tests passed!' in a background tmux window named 'tests'. Queue a message for my next Claude session saying 'Tests completed - ready to deploy'. Then tell me what you did."

    # Demo 4: Record Demo
    record_demo "record" \
        "Explain how the /record skill works and what it does. Keep it brief - just 2-3 sentences about recording Claude sessions as asciinema files."

    echo ""
    echo "========================================"
    echo "All demos generated!"
    echo "Files in: $DOCS_DIR/"
    echo "========================================"
    ls -la "$DOCS_DIR"/*.cast
}

main "$@"
