#!/usr/bin/env bash
# PreToolUse hook: block destructive git/file commands
# Receives tool input JSON on stdin, outputs permission decision JSON

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

deny() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# Force push (but allow --force-with-lease)
case "$command" in
  *"--force-with-lease"*) ;; # safe, allow through
  *"git push --force"*|*"git push -f"*)
    deny "Blocked: force push. Use --force-with-lease if you really need this."
    ;;
esac

# Destructive git commands
case "$command" in
  *"git reset --hard"*)
    deny "Blocked: git reset --hard discards changes. Stash or commit first."
    ;;
  *"git clean -f"*|*"git clean -df"*|*"git clean -xf"*)
    deny "Blocked: git clean -f removes untracked files permanently."
    ;;
esac

# Dangerous rm targets
# shellcheck disable=SC2221,SC2222 # broader pattern intentionally catches narrower ones
case "$command" in
  *"rm -rf /"*|*"rm -rf /Users"*|*"rm -rf /home"*|*"rm -rf /etc"*|*"rm -rf /var"*)
    deny "Blocked: dangerous rm -rf target."
    ;;
esac
