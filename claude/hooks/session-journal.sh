#!/usr/bin/env bash
# Stop hook: Write session journal entry and update work thread index.
# Runs after session ends — user isn't waiting, so ~500ms is fine.
#
# Input (stdin): JSON with session_id, transcript_path, cwd, hook_event_name
# Output: none required for Stop hooks

set -e

BRAIN_DIR="$HOME/.claude/brain"
JOURNAL_DIR="$BRAIN_DIR/journal"
mkdir -p "$JOURNAL_DIR/handoffs"

input=$(cat)
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty')
CWD=$(echo "$input" | jq -r '.cwd // empty')

# Bail if we don't have the essentials
if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

TODAY=$(date -u +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# --- Extract data from JSONL transcript ---

# Project name from cwd (last path component)
PROJECT=$(basename "$CWD")

# Git branch
BRANCH=$(jq -r 'select(.gitBranch != null) | .gitBranch' "$TRANSCRIPT" 2>/dev/null | head -1)
BRANCH=${BRANCH:-"unknown"}

# Count messages by type (use grep for speed on large files)
USER_COUNT=$(grep -c '"type":"user"' "$TRANSCRIPT" 2>/dev/null || grep -c '"type": "user"' "$TRANSCRIPT" 2>/dev/null || echo 0)
ASSISTANT_COUNT=$(grep -c '"type":"assistant"' "$TRANSCRIPT" 2>/dev/null || grep -c '"type": "assistant"' "$TRANSCRIPT" 2>/dev/null || echo 0)

# Tool usage counts
TOOL_COUNTS=$(jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "tool_use") | .name' "$TRANSCRIPT" 2>/dev/null | sort | uniq -c | sort -rn | head -8 | while read count name; do echo -n "$name: $count, "; done | sed 's/, $//')

# First user text message (the task) — skip image-only or empty messages
TASK=$(jq -r 'select(.type == "user" and .userType == "external") | .message.content[]? | select(.type == "text") | .text | select(test("^\\[Image") | not)' "$TRANSCRIPT" 2>/dev/null | head -1 | head -c 150 | tr '\n' ' ' | tr '"' "'")

# Skills used (slash commands in user messages)
SKILLS=$(jq -r 'select(.type == "user" and .userType == "external") | .message.content[]? | select(.type == "text") | .text' "$TRANSCRIPT" 2>/dev/null | grep -oE '^/(review|verify|sync-to-dotfiles|sync-from-dotfiles|threads|resume|handoff|focus|compact|context|mcp)' 2>/dev/null | sort -u | tr '\n' ', ' | sed 's/,$//')

# Detect corrections (user messages with negative signals)
CORRECTIONS=$(jq -r 'select(.type == "user" and .userType == "external") | .message.content[]? | select(.type == "text") | .text' "$TRANSCRIPT" 2>/dev/null | grep -ciE '(^no[,. ]|don.t do|stop |wrong|revert|undo|not what I)' || true)

# Check if commits were made
COMMITS=$(jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "Bash") | .input.command // ""' "$TRANSCRIPT" 2>/dev/null | grep -c 'git commit' || true)

# Last assistant text (for handoff extraction)
LAST_ASSISTANT=$(jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' "$TRANSCRIPT" 2>/dev/null | tail -30 | head -c 500 | tr '\n' ' ' | tr '"' "'")

# --- Write journal entry ---
JOURNAL_FILE="$JOURNAL_DIR/$TODAY.yaml"

# Create file with header if new
if [ ! -f "$JOURNAL_FILE" ]; then
  echo "# Session journal for $TODAY" > "$JOURNAL_FILE"
fi

cat >> "$JOURNAL_FILE" << ENTRY

- session_id: "$SESSION_ID"
  timestamp: "$TIMESTAMP"
  project: "$PROJECT"
  branch: "$BRANCH"
  cwd: "$CWD"
  task: "$TASK"
  messages: {user: $USER_COUNT, assistant: $ASSISTANT_COUNT}
  tools: {$TOOL_COUNTS}
  skills_used: [$SKILLS]
  corrections: $CORRECTIONS
  commits: $COMMITS
ENTRY

# --- Update threads.json ---
THREADS_FILE="$JOURNAL_DIR/threads.json"

# Create if doesn't exist (use JSON format for jq compatibility)
if [ ! -f "$THREADS_FILE" ]; then
  echo '{"threads": []}' > "$THREADS_FILE"
fi

# Thread ID: project-branch (sanitized)
THREAD_ID=$(echo "${PROJECT}-${BRANCH}" | tr '/' '-' | tr ' ' '-' | head -c 60)

# Check if thread exists
if jq -e ".threads[] | select(.id == \"$THREAD_ID\")" "$THREADS_FILE" &>/dev/null; then
  # Update existing thread
  tmp=$(mktemp)
  jq --arg id "$THREAD_ID" \
     --arg ts "$TIMESTAMP" \
     --arg task "$TASK" \
     '(.threads[] | select(.id == $id)) |= (
       .last_session = $ts |
       .session_count = (.session_count + 1) |
       .last_task = $task
     )' "$THREADS_FILE" > "$tmp" && mv "$tmp" "$THREADS_FILE"
else
  # Create new thread
  tmp=$(mktemp)
  jq --arg id "$THREAD_ID" \
     --arg project "$PROJECT" \
     --arg branch "$BRANCH" \
     --arg ts "$TIMESTAMP" \
     --arg task "$TASK" \
     --arg cwd "$CWD" \
     '.threads += [{
       id: $id,
       project: $project,
       branch: $branch,
       cwd: $cwd,
       summary: $task,
       last_session: $ts,
       last_task: $task,
       session_count: 1,
       status: "active"
     }]' "$THREADS_FILE" > "$tmp" && mv "$tmp" "$THREADS_FILE"
fi

# --- Update meta.yaml ---
META_FILE="$JOURNAL_DIR/meta.yaml"

if [ ! -f "$META_FILE" ]; then
  cat > "$META_FILE" << META
session_count_since_review: 0
total_sessions: 0
last_review: "never"
review_threshold: 10
META
fi

# Increment counters (simple sed since meta.yaml is small and flat)
CURRENT_SINCE=$(grep 'session_count_since_review' "$META_FILE" | grep -oE '[0-9]+')
CURRENT_TOTAL=$(grep 'total_sessions' "$META_FILE" | grep -oE '[0-9]+')
NEW_SINCE=$((CURRENT_SINCE + 1))
NEW_TOTAL=$((CURRENT_TOTAL + 1))

sed -i.bak "s/session_count_since_review: .*/session_count_since_review: $NEW_SINCE/" "$META_FILE"
sed -i.bak "s/total_sessions: .*/total_sessions: $NEW_TOTAL/" "$META_FILE"
rm -f "$META_FILE.bak"

# Set review-due marker if threshold hit
THRESHOLD=$(grep 'review_threshold' "$META_FILE" | grep -oE '[0-9]+')
if [ "$NEW_SINCE" -ge "$THRESHOLD" ]; then
  touch "$JOURNAL_DIR/.review-due"
fi

# --- Push brain to remote ---
"$(dirname "$0")/brain-sync.sh" push
