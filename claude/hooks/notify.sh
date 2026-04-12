#!/usr/bin/env bash
# Notification hook: platform-aware alerts when Claude needs attention
# Reads JSON from stdin for context (cwd, message, etc.)
# Only sends desktop notifications — no terminal bells or escape sequences

# Ensure homebrew binaries are in PATH
export PATH="/opt/homebrew/bin:$PATH"

# Parse hook input from stdin
INPUT=$(cat)
MSG=$(echo "$INPUT" | jq -r '.message // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

# Fallback if no JSON input
MSG="${MSG:-Claude Code needs attention}"

# Derive project name from working directory
if [ -n "$CWD" ]; then
  PROJECT=$(basename "$CWD")
else
  PROJECT=$(basename "$PWD")
fi

TITLE="Claude Code — $PROJECT"

# Sanitize to avoid shell injection
MSG=$(echo "$MSG" | head -c 200 | tr "'" " " | tr '"' " " | tr '`' " " | tr '$' " ")
TITLE=$(echo "$TITLE" | head -c 100 | tr "'" " " | tr '"' " " | tr '`' " " | tr '$' " ")

if [ "$(uname -s)" = "Darwin" ]; then
  # Desktop notification via terminal-notifier (stays until dismissed)
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "$TITLE" -message "$MSG" \
      -sound Blow -group "claude-$$" \
      -activate com.mitchellh.ghostty
  else
    # Fallback to osascript (auto-dismisses)
    osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"Blow\"" 2>/dev/null
  fi
elif command -v notify-send >/dev/null 2>&1; then
  notify-send --urgency=normal "$TITLE" "$MSG" 2>/dev/null
fi
