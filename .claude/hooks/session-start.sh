#!/bin/bash
set -euo pipefail

# SessionStart hook: inject the master architecture rules into Claude's
# context at the start of every session (stdout of a SessionStart hook is
# added to context automatically).

SPEC_FILE="$CLAUDE_PROJECT_DIR/MASTER_ARCHITECTURE_SPEC.md"

if [ -f "$SPEC_FILE" ]; then
  echo "=== MANDATORY ARCHITECTURE RULES (loaded automatically at session start) ==="
  echo "All code, schema and UI changes in this session MUST comply with the following spec:"
  echo
  cat "$SPEC_FILE"
fi
