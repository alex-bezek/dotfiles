#!/usr/bin/env bash
# Notification hook: platform-aware alerts when Claude needs attention
# Reads JSON from stdin for context (cwd, message, etc.)

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

# Get iTerm tab name if available
ITERM_TAB=""
if [ "$TERM_PROGRAM" = "iTerm.app" ] || [ -n "$ITERM_SESSION_ID" ]; then
  ITERM_TAB=$(osascript -e '
    tell application "iTerm2"
      tell current session of current tab of current window
        return name of current tab of current window
      end tell
    end tell
  ' 2>/dev/null)
fi

# Build title with project/tab context
if [ -n "$ITERM_TAB" ] && [ "$ITERM_TAB" != "$PROJECT" ]; then
  TITLE="Claude Code — $ITERM_TAB"
else
  TITLE="Claude Code — $PROJECT"
fi

# Sanitize to avoid shell injection
MSG=$(echo "$MSG" | head -c 200 | tr "'" " " | tr '"' " " | tr '`' " " | tr '$' " ")
TITLE=$(echo "$TITLE" | head -c 100 | tr "'" " " | tr '"' " " | tr '`' " " | tr '$' " ")

if [ "$(uname -s)" = "Darwin" ]; then
  # Sticky notification via terminal-notifier (stays until dismissed)
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "$TITLE" -message "$MSG" \
      -sound Blow -group "claude-$$" \
      -activate com.googlecode.iterm2
  else
    # Fallback to osascript (auto-dismisses)
    osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"Blow\"" 2>/dev/null
  fi

  # iTerm2: flash dock icon once (not the persistent bounce)
  printf '\e]1337;RequestAttention=once\a' 2>/dev/null
elif command -v notify-send >/dev/null 2>&1; then
  notify-send --urgency=normal "$TITLE" "$MSG" 2>/dev/null
  printf '\a'
else
  printf '\a'
fi
