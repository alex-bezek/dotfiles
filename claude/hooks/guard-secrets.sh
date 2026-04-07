#!/usr/bin/env bash
# PreToolUse hook: scan staged files for secrets before git commit
# This runs inside Claude Code and cannot be bypassed with --no-verify

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only check git commit commands
case "$command" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# Skip if nothing is staged
FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
if [ -z "$FILES" ]; then
  exit 0
fi

deny() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

SECRET_PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'sk-[a-zA-Z0-9]{20,}'
  'ghp_[a-zA-Z0-9]{36}'
  'gho_[a-zA-Z0-9]{36}'
  'github_pat_[a-zA-Z0-9_]{22,}'
  'xoxb-[0-9a-zA-Z-]+'
  'xoxp-[0-9a-zA-Z-]+'
  'xapp-[0-9a-zA-Z-]+'
  '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'
  'password\s*[:=]\s*["\x27][^"\x27]{8,}'
  'secret\s*[:=]\s*["\x27][^"\x27]{8,}'
  'token\s*[:=]\s*["\x27][^"\x27]{8,}'
  'api_key\s*[:=]\s*["\x27][^"\x27]{8,}'
)

SKIP_FILES='\.png$|\.jpg$|\.gif$|\.ico$|\.woff|\.ttf$|\.lock$|\.sum$'

for file in $FILES; do
  if echo "$file" | grep -qE "$SKIP_FILES"; then
    continue
  fi
  if [ ! -f "$file" ]; then
    continue
  fi

  STAGED=$(git diff --cached -- "$file" | grep '^+[^+]' || true)
  if [ -z "$STAGED" ]; then
    continue
  fi

  for pattern in "${SECRET_PATTERNS[@]}"; do
    if echo "$STAGED" | grep -qE "$pattern" 2>/dev/null; then
      deny "Blocked: possible secret detected in $file. Remove the secret before committing."
    fi
  done
done

# Block .env files
ENV_FILES=$(echo "$FILES" | grep -E '(^|/)\.env(\.|$)' || true)
if [ -n "$ENV_FILES" ]; then
  deny "Blocked: .env file staged for commit ($ENV_FILES). Remove it from staging."
fi
