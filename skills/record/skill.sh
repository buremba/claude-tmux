#!/usr/bin/env bash
# Skill entry point for /record command
# Delegates to scripts/record.sh with arguments

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORD_SCRIPT="$SKILL_DIR/scripts/record.sh"

# Forward all arguments to record.sh
exec "$RECORD_SCRIPT" "$@"
