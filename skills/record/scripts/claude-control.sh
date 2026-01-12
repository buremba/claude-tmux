#!/usr/bin/env bash
# Claude session management for recording
# Handles Claude initialization, control, and shutdown

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Claude Initialization
# ============================================================================

# Start Claude in a tmux session
start_claude_in_session() {
  local session="$1"
  local flags="${2:---dangerously-skip-permissions}"

  if ! verify_target "$session"; then
    return 1
  fi

  log_info "Starting Claude in session: $session"

  # Send command to start Claude
  send_keys "$session" "claude $flags"
  sleep 0.5
  send_keys "$session" "Enter"

  # Wait for Claude to initialize (allow up to 60 seconds)
  if ! wait_for_claude_ready "$session" 60; then
    log_error "Claude failed to initialize"
    return 1
  fi

  log_success "Claude initialized and ready"
  return 0
}

# Wait for Claude UI to be ready and responsive
wait_claude_ready_ui() {
  local session="$1"
  local timeout="${2:-30}"

  if ! verify_target "$session"; then
    return 1
  fi

  log_info "Waiting for Claude UI to be ready (timeout: ${timeout}s)"

  # Look for Claude's input prompt (> character at line start)
  # This appears after the welcome banner
  if wait_for_text "$session" "^>" "$timeout" 0.5; then
    return 0
  fi

  log_warn "Claude UI ready signal not detected, proceeding anyway"
  return 0
}

# ============================================================================
# Claude Interaction Helpers
# ============================================================================

# Send a Claude prompt with standard delays for readability
send_claude_prompt() {
  local session="$1"
  local prompt="$2"
  local wait_timeout="${3:-60}"
  local pre_delay="${4:-1}"
  local post_delay="${5:-2}"

  if ! verify_target "$session"; then
    return 1
  fi

  # Delay before sending (for recording pacing)
  if (( pre_delay > 0 )); then
    sleep "$pre_delay"
  fi

  # Send the prompt
  send_prompt_and_wait "$session" "$prompt" "$wait_timeout"
  local result=$?

  # Delay after response (for recording readability)
  if (( post_delay > 0 )); then
    sleep "$post_delay"
  fi

  return $result
}

# Send multiple prompts in sequence
send_claude_prompts() {
  local session="$1"
  shift  # Rest are prompts with optional timeouts

  local i=1
  while (( i <= $# )); do
    local prompt="${!i}"
    (( i++ ))

    # Check if next arg is a number (timeout)
    local timeout=60
    if (( i <= $# )); then
      local next="${!i}"
      if [[ "$next" =~ ^[0-9]+$ ]]; then
        timeout="$next"
        (( i++ ))
      fi
    fi

    log_info "Sending prompt $((i/2)): ${prompt:0:50}..."
    send_claude_prompt "$session" "$prompt" "$timeout"
  done
}

# Request Claude to use a specific plugin script
request_plugin_script() {
  local session="$1"
  local script_name="$2"
  local args="${3:-}"

  if ! verify_target "$session"; then
    return 1
  fi

  log_info "Requesting Claude to use plugin script: $script_name $args"

  local prompt="Use the $script_name script from ~/.claude/plugins/claude-tmux/skills/tmux-awareness/scripts/ with arguments: $args"

  send_claude_prompt "$session" "$prompt" 45
}

# Request Claude to spawn a pane
request_spawn_pane() {
  local session="$1"
  local direction="$2"  # h or v
  local percentage="${3:-30}"
  local command="${4:-echo 'pane content' && sleep 300}"

  if ! verify_target "$session"; then
    return 1
  fi

  log_info "Requesting Claude to spawn pane: direction=$direction, size=$percentage%, command=$command"

  local prompt="Spawn a $direction split pane using spawn-pane.sh taking $percentage% of the space with command: $command"

  send_claude_prompt "$session" "$prompt" 45
}

# Request Claude to spawn a window
request_spawn_window() {
  local session="$1"
  local window_name="$2"
  local command="$3"

  if ! verify_target "$session"; then
    return 1
  fi

  log_info "Requesting Claude to spawn window: name=$window_name, command=$command"

  local prompt="Create a tmux window named '$window_name' using spawn-window.sh with command: $command"

  send_claude_prompt "$session" "$prompt" 45
}

# ============================================================================
# Claude Shutdown
# ============================================================================

# Gracefully exit Claude from session
exit_claude_clean() {
  local session="$1"

  if ! verify_target "$session"; then
    return 1
  fi

  log_info "Exiting Claude gracefully"

  # Send /exit command
  send_keys "$session" "/exit"
  sleep 0.5
  send_keys "$session" "Enter"

  # Wait for Claude to process exit
  sleep 3

  log_success "Claude exited"
}

# ============================================================================
# Session Verification
# ============================================================================

# Verify Claude is running in session
verify_claude_running() {
  local session="$1"

  if ! verify_target "$session"; then
    return 1
  fi

  # Check if claude command is running in the pane
  local output=$(capture_pane "$session" -5)

  if echo "$output" | grep -qiE "claude|crafting|thinking"; then
    log_success "Claude is active in $session"
    return 0
  fi

  log_warn "Claude may not be running in $session"
  return 1
}

# Get Claude UI state (simple heuristic)
get_claude_state() {
  local session="$1"
  local lines="${2:--10}"

  if ! verify_target "$session"; then
    return 1
  fi

  local output=$(capture_pane "$session" "$lines")

  if echo "$output" | grep -qi "crafting\|thinking"; then
    echo "thinking"
  elif echo "$output" | grep -qi "waiting\|ready\|help"; then
    echo "idle"
  else
    echo "unknown"
  fi
}

# Wait for Claude to finish current task (not thinking anymore)
wait_claude_idle() {
  local session="$1"
  local timeout="${2:-120}"

  if ! verify_target "$session"; then
    return 1
  fi

  log_info "Waiting for Claude to finish current task (timeout: ${timeout}s)"

  local start=$(date +%s)
  local deadline=$((start + timeout))

  while true; do
    local state=$(get_claude_state "$session")

    if [ "$state" = "idle" ]; then
      log_success "Claude is idle and ready"
      return 0
    fi

    local now=$(date +%s)
    if (( now >= deadline )); then
      log_warn "Timeout waiting for Claude to become idle"
      return 1
    fi

    sleep 1
  done
}

# ============================================================================
# Exports for use in templates
# ============================================================================

export -f start_claude_in_session wait_claude_ready_ui
export -f send_claude_prompt send_claude_prompts
export -f request_plugin_script request_spawn_pane request_spawn_window
export -f exit_claude_clean verify_claude_running
export -f get_claude_state wait_claude_idle
