#!/usr/bin/env bash
# Setup hook: Pull brain and show project count at session start.
#
# Input (stdin): JSON with session_id, cwd, hook_event_name
# Output: JSON with additionalContext (if there's anything to show)

BRAIN_DIR="$HOME/.claude/brain"

# Pull latest brain state
"$(dirname "$0")/brain-sync.sh" pull

# Count tracked projects
if [ -f "$BRAIN_DIR/projects.yaml" ]; then
  COUNT=$(grep -c '^ *- id:' "$BRAIN_DIR/projects.yaml" 2>/dev/null || echo 0)
  if [ "$COUNT" -gt 0 ]; then
    MSG="You have $COUNT tracked project(s). Use /focus <topic> or /projects to see them."
    echo "{\"additionalContext\": \"$MSG\"}"
  fi
fi
