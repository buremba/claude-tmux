#!/usr/bin/env bash
# Recording orchestrator for tmux demo recordings
# Simply: start Claude, send a prompt, record it, exit cleanly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/validate-deps.sh"
source "$SCRIPT_DIR/claude-control.sh"

# Configuration
DEFAULT_WIDTH=120
DEFAULT_HEIGHT=35
DEFAULT_IDLE_TIME=2

# ============================================================================
# Help and Usage
# ============================================================================

show_usage() {
  cat << 'EOF'
Usage: record.sh -p|--prompt "PROMPT" [OPTIONS]

Record Claude executing a prompt in tmux.

REQUIRED:
  -p, --prompt TEXT          Prompt for Claude to execute

OPTIONS:
  -w, --width WIDTH          Terminal width in columns (default: 120)
  -h, --height HEIGHT        Terminal height in rows (default: 35)
  -o, --output FILE.cast     Output file path (default: recordings/{timestamp}.cast)
  -i, --idle-time SECONDS    Max idle time for compression (default: 2)
  -t, --timeout SECONDS      Timeout waiting for Claude response (default: 120)
  --help                     Show this help message

EXAMPLES:
  # Record Claude checking tmux status
  record.sh -p "Check tmux context using detect-session.sh"

  # Record with custom output
  record.sh -p "Show all panes and windows" -o my-demo.cast

  # Custom dimensions
  record.sh -p "Your prompt" -w 100 -h 30

ENVIRONMENT:
  CLAUDE_TMUX_RECORD_WIDTH   Override default width
  CLAUDE_TMUX_RECORD_HEIGHT  Override default height

EOF
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_args() {
  local prompt=""
  local width="$DEFAULT_WIDTH"
  local height="$DEFAULT_HEIGHT"
  local idle_time="$DEFAULT_IDLE_TIME"
  local timeout=120
  local output=""

  while [[ $# -gt 0 ]]; do
    # Skip empty arguments
    if [ -z "$1" ]; then
      shift
      continue
    fi

    case "$1" in
      -p|--prompt)
        prompt="$2"
        shift 2
        ;;
      -w|--width)
        width="$2"
        shift 2
        ;;
      -h|--height)
        height="$2"
        shift 2
        ;;
      -i|--idle-time)
        idle_time="$2"
        shift 2
        ;;
      -t|--timeout)
        timeout="$2"
        shift 2
        ;;
      -o|--output)
        output="$2"
        shift 2
        ;;
      --help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

  # Validate required prompt
  if [ -z "$prompt" ]; then
    log_error "Prompt is required"
    show_usage
    exit 1
  fi

  # Use environment overrides if set
  width="${CLAUDE_TMUX_RECORD_WIDTH:-$width}"
  height="${CLAUDE_TMUX_RECORD_HEIGHT:-$height}"

  # Return values - use %q for safe eval
  printf 'prompt=%q\n' "$prompt"
  echo "width=$width"
  echo "height=$height"
  echo "idle_time=$idle_time"
  echo "timeout=$timeout"
  printf 'output=%q\n' "$output"
}

# ============================================================================
# Recording Setup
# ============================================================================

setup_recording() {
  local width="$1"
  local height="$2"
  local output="$3"

  log_info "=== Setting Up Recording ==="
  log_info "Dimensions: ${width}x${height}"
  log_info "Idle time limit: ${2}s"

  # Set output path if not specified
  if [ -z "$output" ]; then
    local recordings_dir="$SKILL_ROOT/recordings"
    mkdir -p "$recordings_dir"
    output="$recordings_dir/recording-$(timestamp).cast"
  fi

  # Validate output directory
  if ! validate_output_path "$output"; then
    return 1
  fi

  log_info "Output: $output"

  # Validate dependencies
  if ! validate_all; then
    log_error "Validation failed, cannot proceed"
    return 1
  fi

  echo "$output"
}

# ============================================================================
# Main Recording Workflow
# ============================================================================

run_recording() {
  local prompt="$1"
  local width="$2"
  local height="$3"
  local idle_time="$4"
  local timeout="$5"
  local output="$6"

  log_info "=== Starting Recording Workflow ==="

  # REQUIRE being inside tmux - we need to know the current session
  if [ -z "${TMUX:-}" ]; then
    log_error "Must run inside a tmux session"
    log_error "Start tmux first: tmux new -s mysession"
    return 1
  fi

  # Get current session info
  local session
  session=$(get_current_session) || {
    log_error "Failed to get current tmux session"
    return 1
  }
  log_info "Recording in session: $session"

  # Create a unique window name for this recording
  local window_name="claude-record-$$"

  # Create a new tmux window for the recording
  log_info "Creating recording window: $window_name"
  tmux new-window -t "$session" -n "$window_name" -d

  # Get the full target for this window
  local target="$session:$window_name"

  # Resize the window to the specified dimensions
  # This is important when running from a non-interactive terminal
  tmux resize-window -t "$target" -x "$width" -y "$height" 2>/dev/null || true

  # Save the prompt to a temp file for the sender script
  local prompt_file="/tmp/claude-prompt-$$.txt"
  printf '%s' "$prompt" > "$prompt_file"

  # Create a script that will send keys to the recording window
  # This runs in the background while asciinema records
  local sender_script="/tmp/claude-sender-$$.sh"
  cat > "$sender_script" << 'SENDER'
#!/bin/bash
target="$1"
prompt_file="$2"
timeout="$3"

# Wait for Claude to start and be ready
sleep 3

# Send the prompt (escape special tmux characters)
prompt=$(cat "$prompt_file")
tmux send-keys -t "$target" -l "$prompt"
tmux send-keys -t "$target" Enter

# Wait for Claude to process (poll until we see output settling)
waited=0
while [ $waited -lt $timeout ]; do
  sleep 5
  waited=$((waited + 5))

  # Check if Claude finished (look for prompt ">" at start of line)
  output=$(tmux capture-pane -t "$target" -p 2>/dev/null | tail -20)
  if echo "$output" | grep -q "^>" 2>/dev/null; then
    # Give it a moment to fully complete
    sleep 3
    break
  fi
done

# Send /exit to quit Claude
tmux send-keys -t "$target" "/exit" Enter
sleep 2

# Exit the window
tmux send-keys -t "$target" "exit" Enter
SENDER
  chmod +x "$sender_script"

  # Start Claude in the recording window
  tmux send-keys -t "$target" "claude --dangerously-skip-permissions" Enter

  # Start the sender script in background (it will type the prompt after Claude is ready)
  "$sender_script" "$target" "$prompt_file" "$timeout" &
  local sender_pid=$!

  log_info "Recording with asciinema (attaching to tmux to capture splits)"
  log_info "Max recording time: ${timeout}s"

  # Run asciinema with a hard timeout to prevent huge files
  # This captures the FULL tmux UI including any split panes Claude creates
  # We unset TMUX to allow attaching from within a tmux session
  TMUX= timeout "${timeout}s" asciinema rec \
    --idle-time-limit "$idle_time" \
    --window-size "${width}x${height}" \
    --overwrite \
    "$output" \
    -c "tmux attach -t '$target'" || true

  # Kill sender if still running
  kill $sender_pid 2>/dev/null || true

  local exit_code=$?

  # Cleanup - kill the recording window if it still exists
  tmux kill-window -t "$target" 2>/dev/null || true
  rm -f "$sender_script" "$prompt_file"

  if [ $exit_code -ne 0 ]; then
    log_error "Recording failed with exit code: $exit_code"
    return 1
  fi

  # Verify output file
  if [ ! -f "$output" ]; then
    log_error "Recording file was not created: $output"
    return 1
  fi

  local file_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null || echo 0)
  log_success "Recording complete: $output ($((file_size / 1024))KB)"

  # Show next steps
  log_info "Play recording with: asciinema play '$output'"
  log_info "Upload to asciinema.org with: asciinema upload '$output'"

  return 0
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
  local start_time=$(date +%s)

  # Handle --help before logging
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      show_usage
      exit 0
    fi
  done

  log_info "=== Claude Tmux Record ==="

  # Parse arguments
  local args
  args=$(parse_args "$@") || exit 1

  # Extract values
  local prompt width height idle_time timeout output
  eval "$args"

  # Setup recording
  output=$(setup_recording "$width" "$height" "$output") || {
    log_error "Recording setup failed"
    exit 1
  }

  # Run recording
  if run_recording "$prompt" "$width" "$height" "$idle_time" "$timeout" "$output"; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_success "=== Recording Success ==="
    log_info "Total time: $(format_duration $duration)"
    exit 0
  else
    log_error "=== Recording Failed ==="
    exit 1
  fi
}

# ============================================================================
# Run Main
# ============================================================================

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
