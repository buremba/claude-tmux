#!/usr/bin/env bash
# Common utilities for record skill
# Shared functions for timing, tmux operations, and control

set -euo pipefail

# Color output for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}ℹ${NC} $*" >&2
}

log_success() {
  echo -e "${GREEN}✓${NC} $*" >&2
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $*" >&2
}

log_error() {
  echo -e "${RED}✗${NC} $*" >&2
}

# ============================================================================
# Tmux Operations
# ============================================================================

# Verify tmux target exists
verify_target() {
  local target="$1"
  if ! tmux has-session -t "$target" 2>/dev/null; then
    log_error "Target $target does not exist"
    return 1
  fi
}

# Capture pane content
capture_pane() {
  local target="$1"
  local lines="${2:--20}"  # Last 20 lines by default

  if ! verify_target "$target"; then
    return 1
  fi

  tmux capture-pane -p -t "$target" -S "$lines"
}

# Check if text appears in pane
pane_contains() {
  local target="$1"
  local pattern="$2"
  local lines="${3:--50}"

  capture_pane "$target" "$lines" | grep -qE "$pattern"
}

# Send keys to tmux pane
send_keys() {
  local target="$1"
  shift

  if ! verify_target "$target"; then
    return 1
  fi

  tmux send-keys -t "$target" "$@"
}

# Add visual separator for recording clarity
add_separator() {
  local target="$1"
  local text="${2:-====================================}"

  send_keys "$target" "" Enter
  sleep 0.3
  send_keys "$target" "echo '$text'" Enter
  sleep 0.3
}

# Type text with optional delays (simulates typing for effect)
human_type() {
  local target="$1"
  local text="$2"
  local delay="${3:-0}"  # Delay between characters in seconds

  if [ "$delay" = "0" ]; then
    send_keys "$target" "$text"
  else
    for (( i=0; i<${#text}; i++ )); do
      send_keys "$target" "${text:$i:1}"
      sleep "$delay"
    done
  fi
}

# ============================================================================
# Waiting and Polling
# ============================================================================

# Wait for text pattern in pane (polls every 0.5s)
wait_for_text() {
  local target="$1"
  local pattern="$2"
  local timeout="${3:-60}"
  local poll_interval="${4:-0.5}"

  if ! verify_target "$target"; then
    return 1
  fi

  local start=$(date +%s)
  local deadline=$((start + timeout))

  while true; do
    if pane_contains "$target" "$pattern"; then
      log_success "Found pattern in $target: $pattern"
      return 0
    fi

    local now=$(date +%s)
    if (( now >= deadline )); then
      log_warn "Timeout waiting for pattern in $target: $pattern"
      return 1
    fi

    sleep "$poll_interval"
  done
}

# Wait for shell prompt to reappear (indicates command completion)
wait_for_prompt() {
  local target="$1"
  local timeout="${2:-60}"

  # Look for common shell prompts at start of line
  # Matches: $ (bash), > (zsh default), ❯ (oh-my-zsh), # (root)
  wait_for_text "$target" '^[❯$#>] ' "$timeout"
}

# Wait for Claude to initialize in session
wait_for_claude_ready() {
  local target="$1"
  local timeout="${2:-30}"

  # Look for Claude's input prompt (> at line start)
  wait_for_text "$target" "^>" "$timeout"
}

# ============================================================================
# Claude Interaction
# ============================================================================

# Send prompt to Claude and wait for response
send_prompt_and_wait() {
  local target="$1"
  local prompt="$2"
  local timeout="${3:-60}"

  if ! verify_target "$target"; then
    return 1
  fi

  log_info "Sending prompt to $target: ${prompt:0:50}..."

  # Send the prompt
  send_keys "$target" "$prompt"
  sleep 0.3
  send_keys "$target" "Enter"

  # Wait for Claude to finish (shell prompt returns)
  if ! wait_for_prompt "$target" "$timeout"; then
    log_warn "Claude response timeout (may still be processing)"
    return 1
  fi

  log_success "Claude response received"
  return 0
}

# Send prompt without waiting (for fire-and-forget)
send_prompt_no_wait() {
  local target="$1"
  local prompt="$2"

  if ! verify_target "$target"; then
    return 1
  fi

  log_info "Sending prompt (no wait): ${prompt:0:50}..."
  send_keys "$target" "$prompt"
  sleep 0.3
  send_keys "$target" "Enter"
}

# Confirm last prompt (press Enter again)
confirm_prompt() {
  local target="$1"

  send_keys "$target" "Enter"
}

# ============================================================================
# Session Management
# ============================================================================

# Get current tmux session name (requires being inside tmux)
get_current_session() {
  if [ -z "${TMUX:-}" ]; then
    log_error "Not inside a tmux session"
    return 1
  fi
  tmux display-message -p '#S'
}

# Create a new window in the current session for recording
create_window_in_session() {
  local session="$1"
  local name="$2"
  local width="${3:-120}"
  local height="${4:-35}"

  log_info "Creating window '$name' in session '$session'"

  # Create detached window
  tmux new-window -d -t "$session" -n "$name"

  # Get the window target
  local target="${session}:${name}"

  sleep 0.5
  log_success "Window created: $target"
  echo "$target"
}

# Kill only the recording window (not the whole session)
cleanup_window() {
  local target="$1"

  if [ -z "$target" ]; then
    return 0
  fi

  log_info "Cleaning up window: $target"

  # Kill just this window
  tmux kill-window -t "$target" 2>/dev/null || true

  log_success "Window cleaned up: $target"
}

# Legacy: Create isolated tmux session (kept for compatibility)
create_session() {
  local session="$1"
  local width="${2:-120}"
  local height="${3:-35}"

  if tmux has-session -t "$session" 2>/dev/null; then
    log_warn "Session $session already exists, killing it"
    tmux kill-session -t "$session"
    sleep 0.5
  fi

  log_info "Creating tmux session: $session ($width x $height)"
  tmux new-session -d -s "$session" -x "$width" -y "$height"
  sleep 1
  log_success "Session created: $session"
}

# Legacy: Kill session and all its windows (kept for compatibility)
cleanup_session() {
  local session="$1"

  if ! tmux has-session -t "$session" 2>/dev/null; then
    return 0
  fi

  log_info "Cleaning up session: $session"
  tmux kill-session -t "$session" 2>/dev/null || true
  log_success "Session cleaned up: $session"
}

# Get list of windows in session
list_windows() {
  local session="$1"

  if ! verify_target "$session"; then
    return 1
  fi

  tmux list-windows -t "$session" -F '#{window_index}:#{window_name}'
}

# Get list of panes in target
list_panes() {
  local target="$1"

  if ! verify_target "$target"; then
    return 1
  fi

  tmux list-panes -t "$target" -F '#{pane_index}:#{pane_current_command}'
}

# ============================================================================
# Recording Control
# ============================================================================

# Start asciinema recording from outside tmux session
start_recording() {
  local session="$1"
  local output="$2"
  local width="${3:-120}"
  local height="${4:-35}"
  local idle_time="${5:-2}"

  log_info "Starting asciinema recording: $output ($width x $height)"

  # Record from outside tmux to capture all panes/windows
  # --window-size is critical for dimension control (not --cols/--rows)
  # Redirect stdout/stderr to /dev/null so the recording doesn't get interrupted by broken pipe
  asciinema rec \
    --idle-time-limit "$idle_time" \
    --window-size "${width}x${height}" \
    --overwrite \
    "$output" \
    -c "tmux attach -t $session" >/dev/null 2>&1 &

  local pid=$!
  echo "$pid"

  log_success "Recording started (PID: $pid)"

  # Wait for asciinema to attach to tmux
  sleep 3
}

# Stop recording and wait for completion
stop_recording() {
  local pid="$1"
  local timeout="${2:-30}"

  if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    log_warn "Recording process not found or already stopped"
    return 0
  fi

  log_info "Stopping recording (PID: $pid)"

  # Wait for process to finish naturally
  local start=$(date +%s)
  local deadline=$((start + timeout))

  while kill -0 "$pid" 2>/dev/null; do
    if (( $(date +%s) >= deadline )); then
      log_warn "Recording timeout, force killing (PID: $pid)"
      kill -9 "$pid" 2>/dev/null || true
      break
    fi
    sleep 0.5
  done

  log_success "Recording stopped"
}

# ============================================================================
# Exit Sequences
# ============================================================================

# Graceful Claude exit (/exit → exit shell → recording stops)
exit_claude() {
  local target="$1"

  if ! verify_target "$target"; then
    return 1
  fi

  log_info "Exiting Claude in $target"

  # Send /exit to Claude
  send_keys "$target" "/exit"
  sleep 0.5
  send_keys "$target" "Enter"

  # Wait for Claude to exit
  sleep 3

  log_success "Claude exited"
}

# Exit shell (terminates tmux session)
exit_shell() {
  local target="$1"

  if ! verify_target "$target"; then
    return 1
  fi

  log_info "Exiting shell in $target"

  send_keys "$target" "exit"
  sleep 0.5
  send_keys "$target" "Enter"

  # Session will terminate
  sleep 2

  log_success "Shell exited"
}

# Complete exit sequence for recording
exit_recording() {
  local target="$1"
  local asciinema_pid="${2:-}"

  log_info "Executing exit sequence"

  # Exit Claude first
  if verify_target "$target" 2>/dev/null; then
    exit_claude "$target" || true
    sleep 2
    exit_shell "$target" || true
  fi

  # Stop recording
  if [ -n "$asciinema_pid" ]; then
    stop_recording "$asciinema_pid" 10 || true
  fi

  # Final cleanup
  cleanup_session "$target" || true

  log_success "Exit sequence complete"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Get timestamp for filenames
timestamp() {
  date +%Y%m%d-%H%M%S
}

# Validate file path is writable
validate_output_path() {
  local path="$1"
  local dir=$(dirname "$path")

  if [ ! -d "$dir" ]; then
    log_error "Directory does not exist: $dir"
    return 1
  fi

  if [ ! -w "$dir" ]; then
    log_error "Directory not writable: $dir"
    return 1
  fi

  return 0
}

# Pretty print duration in seconds
format_duration() {
  local seconds=$1
  local mins=$((seconds / 60))
  local secs=$((seconds % 60))

  if (( mins > 0 )); then
    printf "%dm%02ds" "$mins" "$secs"
  else
    printf "%ds" "$secs"
  fi
}

export -f log_info log_success log_warn log_error
export -f verify_target capture_pane pane_contains send_keys add_separator
export -f wait_for_text wait_for_prompt wait_for_claude_ready
export -f send_prompt_and_wait send_prompt_no_wait confirm_prompt
export -f get_current_session create_window_in_session cleanup_window
export -f create_session cleanup_session list_windows list_panes
export -f start_recording stop_recording
export -f exit_claude exit_shell exit_recording
export -f timestamp validate_output_path format_duration
