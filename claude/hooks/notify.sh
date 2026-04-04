#!/usr/bin/env bash
# Notification hook: platform-aware alerts when Claude needs attention
# Sanitize message to avoid shell injection via quotes

MSG="${CLAUDE_NOTIFICATION_MESSAGE:-Claude Code needs attention}"
MSG=$(echo "$MSG" | head -c 200 | tr "'" " " | tr '"' " " | tr '`' " " | tr '$' " ")

if [ "$(uname -s)" = "Darwin" ]; then
  osascript -e "display notification \"$MSG\" with title \"Claude Code\"" 2>/dev/null
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "Claude Code" "$MSG" 2>/dev/null
else
  printf '\a'
fi
