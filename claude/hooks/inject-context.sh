#!/usr/bin/env bash
# Setup hook: Show recent work activity at session start.
# Lightweight orientation — not prescriptive. User can /focus for deep context.
#
# Input (stdin): JSON with session_id, cwd, hook_event_name
# Output: JSON with additionalContext (if there's anything to show)

BRAIN_DIR="$HOME/.claude/brain"
JOURNAL_DIR="$BRAIN_DIR/journal"
THREADS_FILE="$JOURNAL_DIR/threads.json"

# Pull latest brain state
"$(dirname "$0")/brain-sync.sh" pull

# Bail silently if no journal yet
if [ ! -f "$THREADS_FILE" ]; then
  exit 0
fi

input=$(cat)
CWD=$(echo "$input" | jq -r '.cwd // empty')
PROJECT=$(basename "$CWD")

# Get threads for current project, sorted by recency
THIS_PROJECT=$(jq -r --arg proj "$PROJECT" \
  '[.threads[] | select(.status == "active" and .project == $proj)] | sort_by(.last_session) | reverse | .[:5] | .[] | "- [\(.id)] \(.summary | .[:80]) (\(.session_count)s)"' \
  "$THREADS_FILE" 2>/dev/null)

# Count other active threads
OTHER_COUNT=$(jq -r --arg proj "$PROJECT" \
  '[.threads[] | select(.status == "active" and .project != $proj)] | length' \
  "$THREADS_FILE" 2>/dev/null)

CONTEXT=""

if [ -n "$THIS_PROJECT" ]; then
  CONTEXT="Recent threads in $PROJECT:\n$THIS_PROJECT"
fi

if [ "$OTHER_COUNT" -gt 0 ] 2>/dev/null; then
  OTHER_NAMES=$(jq -r --arg proj "$PROJECT" \
    '[.threads[] | select(.status == "active" and .project != $proj)] | sort_by(.last_session) | reverse | .[:3] | .[] | "\(.project)/\(.branch | split("/") | last) (\(.session_count)s)"' \
    "$THREADS_FILE" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
  if [ -n "$CONTEXT" ]; then
    CONTEXT="$CONTEXT\n\nOther active: $OTHER_NAMES"
  else
    CONTEXT="Other active threads: $OTHER_NAMES"
  fi
fi

if [ -n "$CONTEXT" ]; then
  CONTEXT="$CONTEXT\n\nUse /focus <topic> to load context for a workstream."
fi

# Check if review is due
if [ -f "$JOURNAL_DIR/.review-due" ]; then
  REVIEW_NOTE="[Config review due — run /self-review when available]"
  if [ -n "$CONTEXT" ]; then
    CONTEXT="$CONTEXT\n$REVIEW_NOTE"
  else
    CONTEXT="$REVIEW_NOTE"
  fi
fi

if [ -n "$CONTEXT" ]; then
  CONTEXT_ESCAPED=$(printf '%s' "$CONTEXT" | jq -Rs '.')
  echo "{\"additionalContext\": $CONTEXT_ESCAPED}"
fi
