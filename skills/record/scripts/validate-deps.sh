#!/usr/bin/env bash
# Validate dependencies for record skill

set -euo pipefail

# Source common for logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Dependency Checks
# ============================================================================

check_command() {
  local cmd="$1"
  local name="${2:-$cmd}"

  if ! command -v "$cmd" &> /dev/null; then
    log_error "Required command not found: $name"
    return 1
  fi

  log_success "Found: $name"
  return 0
}

check_version() {
  local cmd="$1"
  local version_flag="${2:---version}"
  local min_version="${3:-}"

  if ! command -v "$cmd" &> /dev/null; then
    log_error "Command not found: $cmd"
    return 1
  fi

  local version_output
  version_output=$("$cmd" "$version_flag" 2>&1 || echo "")

  if [ -z "$version_output" ]; then
    log_warn "$cmd version check failed, assuming acceptable"
    return 0
  fi

  log_info "$cmd: $version_output"
  return 0
}

check_file() {
  local file="$1"
  local name="${2:-$file}"

  if [ ! -f "$file" ]; then
    log_error "Required file not found: $name"
    return 1
  fi

  if [ ! -r "$file" ]; then
    log_error "Required file not readable: $name"
    return 1
  fi

  log_success "Found: $name"
  return 0
}

check_directory() {
  local dir="$1"
  local name="${2:-$dir}"

  if [ ! -d "$dir" ]; then
    log_error "Required directory not found: $name"
    return 1
  fi

  if [ ! -r "$dir" ]; then
    log_error "Required directory not readable: $name"
    return 1
  fi

  log_success "Found: $name"
  return 0
}

check_writable_dir() {
  local dir="$1"
  local name="${2:-$dir}"

  if [ ! -d "$dir" ]; then
    mkdir -p "$dir" || {
      log_error "Cannot create directory: $name"
      return 1
    }
  fi

  if [ ! -w "$dir" ]; then
    log_error "Directory not writable: $name"
    return 1
  fi

  log_success "Found (writable): $name"
  return 0
}

# ============================================================================
# Validate Required Tools
# ============================================================================

validate_tools() {
  log_info "Checking required tools..."

  local errors=0

  # Critical dependencies
  check_command "tmux" "tmux (terminal multiplexer)" || (( errors++ ))
  check_command "asciinema" "asciinema (terminal recording)" || (( errors++ ))
  check_command "jq" "jq (JSON processor)" || (( errors++ ))
  check_command "claude" "claude (Claude CLI)" || (( errors++ ))

  # Helper tools (not critical but recommended)
  if check_command "bash" "bash (shell)"; then
    check_version "bash" "--version"
  fi

  return $errors
}

# ============================================================================
# Validate Plugin Structure
# ============================================================================

validate_plugin_structure() {
  log_info "Checking plugin structure..."

  local plugin_dir="${HOME}/.claude/plugins/claude-tmux"
  local errors=0

  check_directory "$plugin_dir" "Plugin directory" || (( errors++ ))

  # Check for tmux-awareness skill (our dependency)
  local tmux_awareness_dir="$plugin_dir/skills/tmux-awareness"
  if [ -d "$tmux_awareness_dir" ]; then
    log_success "Found: tmux-awareness skill"

    # Check for required scripts
    local required_scripts=(
      "scripts/spawn-pane.sh"
      "scripts/spawn-window.sh"
      "scripts/detect-session.sh"
      "scripts/capture-output.sh"
      "scripts/wait-for-text.sh"
      "scripts/queue-message.sh"
    )

    for script in "${required_scripts[@]}"; do
      local script_path="$tmux_awareness_dir/$script"
      if [ -f "$script_path" ]; then
        log_success "Found: $(basename $script)"
      else
        log_warn "Optional script not found: $script"
      fi
    done
  else
    log_warn "tmux-awareness skill not found (optional)"
  fi

  return $errors
}

# ============================================================================
# Validate Templates
# ============================================================================

validate_templates() {
  log_info "Checking templates..."

  local templates_dir="$(dirname "$SCRIPT_DIR")/templates"
  local errors=0

  check_writable_dir "$templates_dir" "Templates directory" || (( errors++ ))

  return $errors
}

# ============================================================================
# Validate Output Directory
# ============================================================================

validate_output_dir() {
  log_info "Checking output directory..."

  local output_dir="$(dirname "$SCRIPT_DIR")/recordings"
  local errors=0

  check_writable_dir "$output_dir" "Recordings directory" || (( errors++ ))

  return $errors
}

# ============================================================================
# Validate Template List
# ============================================================================

validate_template_exists() {
  local template_name="$1"
  local templates_dir="$(dirname "$SCRIPT_DIR")/templates"
  local template_file="$templates_dir/${template_name}.sh"

  if [ ! -f "$template_file" ]; then
    log_error "Template not found: $template_name"
    log_info "Available templates in $templates_dir:"
    ls "$templates_dir"/*.sh 2>/dev/null | xargs -I {} basename {} .sh || echo "No templates found"
    return 1
  fi

  if [ ! -x "$template_file" ]; then
    log_warn "Template is not executable, attempting to fix..."
    chmod +x "$template_file" || {
      log_error "Cannot make template executable: $template_file"
      return 1
    }
  fi

  return 0
}

list_available_templates() {
  # Find templates directory - works whether called from record.sh or validate-deps.sh
  local templates_dir
  if [ -n "${SCRIPT_DIR:-}" ]; then
    templates_dir="$(dirname "$SCRIPT_DIR")/templates"
  else
    templates_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../templates"
  fi

  if [ ! -d "$templates_dir" ]; then
    log_error "Templates directory not found: $templates_dir" >&2
    return 1
  fi

  # Print header to stderr to avoid mixing with output
  log_info "Available templates:" >&2

  # Find templates using find command
  local templates
  templates=$(find "$templates_dir" -maxdepth 1 -name "*.sh" -type f | sort)

  if [ -z "$templates" ]; then
    log_warn "No templates found in $templates_dir" >&2
    return 1
  fi

  while IFS= read -r template_file; do
    local template_name=$(basename "$template_file" .sh)
    echo "  - $template_name"
  done <<< "$templates"
}

# ============================================================================
# Full Validation
# ============================================================================

validate_all() {
  log_info "=== Validating Record Skill Setup ==="

  local errors=0

  validate_tools || (( errors += $? ))
  validate_plugin_structure || (( errors += $? ))
  validate_templates || (( errors += $? ))
  validate_output_dir || (( errors += $? ))

  if (( errors == 0 )); then
    log_success "All validations passed!"
    return 0
  else
    log_error "Validation failed with $errors errors"
    return 1
  fi
}

# ============================================================================
# Main
# ============================================================================

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  validate_all
  exit $?
fi

# Export functions for use by other scripts
export -f check_command check_version check_file check_directory
export -f check_writable_dir validate_template_exists list_available_templates
export -f validate_tools validate_all
