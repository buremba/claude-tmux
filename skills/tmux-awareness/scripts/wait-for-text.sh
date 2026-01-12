#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: wait-for-text.sh -t <target> -p <pattern> [options]

Poll a tmux pane for text and exit when found.

Options:
  -t, --target    Tmux target (session:window.pane), required
  -p, --pattern   Regex pattern to look for, required
  -F, --fixed     Treat pattern as fixed string (not regex)
  -T, --timeout   Seconds to wait (default: 30)
  -i, --interval  Poll interval in seconds (default: 0.5)
  -l, --lines     Number of history lines to inspect (default: 500)
  -h, --help      Show this help

Exit codes:
  0 - Pattern found
  1 - Timeout or error

Examples:
  wait-for-text.sh -t "dev-server:0.0" -p "ready on port"
  wait-for-text.sh -t "agent-1:0.0" -p '^\$' -T 300
USAGE
}

target=""
pattern=""
grep_flag="-E"
timeout=30
interval=0.5
lines=500

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)   target="${2:-}"; shift 2 ;;
    -p|--pattern)  pattern="${2:-}"; shift 2 ;;
    -F|--fixed)    grep_flag="-F"; shift ;;
    -T|--timeout)  timeout="${2:-30}"; shift 2 ;;
    -i|--interval) interval="${2:-0.5}"; shift 2 ;;
    -l|--lines)    lines="${2:-500}"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$target" || -z "$pattern" ]]; then
  echo "Error: --target and --pattern are required" >&2
  usage
  exit 1
fi

if ! [[ "$timeout" =~ ^[0-9]+$ ]]; then
  echo "Error: timeout must be an integer" >&2
  exit 1
fi

# Verify we're in tmux
if ! tmux display-message -p '#{session_name}' >/dev/null 2>&1; then
  echo "Error: Not running inside tmux" >&2
  exit 1
fi

start_epoch=$(date +%s)
deadline=$((start_epoch + timeout))

while true; do
  # Capture pane contents
  # -J joins wrapped lines
  # -S uses negative index to read last N lines
  pane_text=$(tmux capture-pane -p -J -t "$target" -S "-${lines}" 2>/dev/null || true)

  if printf '%s\n' "$pane_text" | grep $grep_flag -- "$pattern" >/dev/null 2>&1; then
    echo '{"found": true, "target": "'"$target"'"}'
    exit 0
  fi

  now=$(date +%s)
  if (( now >= deadline )); then
    echo '{"found": false, "error": "timeout", "target": "'"$target"'", "timeout": '"$timeout"'}' >&2
    exit 1
  fi

  sleep "$interval"
done
