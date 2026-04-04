#!/usr/bin/env bash
# Verify Claude Code dotfiles setup is correct.
# Run this after install to check everything is wired up properly.

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pass=0
fail=0
warn=0

check() {
  if eval "$2" &>/dev/null; then
    echo "  ✓ $1"
    pass=$((pass + 1))
  else
    echo "  ✗ $1"
    fail=$((fail + 1))
  fi
}

check_warn() {
  if eval "$2" &>/dev/null; then
    echo "  ✓ $1"
    pass=$((pass + 1))
  else
    echo "  ~ $1 (optional)"
    warn=$((warn + 1))
  fi
}

# --- Environment ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  CLAUDE_ENV="macos"
elif [[ -n "$CODESPACES" ]]; then
  CLAUDE_ENV="codespaces"
else
  CLAUDE_ENV="linux"
fi
echo "Environment: $CLAUDE_ENV"
echo ""

# --- Symlinks ---
echo "Symlinks:"
check "CLAUDE.md is symlinked" "[ -L '$CLAUDE_DIR/CLAUDE.md' ]"
check "settings.json is symlinked" "[ -L '$CLAUDE_DIR/settings.json' ]"
check "statusline.sh is symlinked" "[ -L '$CLAUDE_DIR/statusline.sh' ]"
check "statusline.sh is executable" "[ -x '$CLAUDE_DIR/statusline.sh' ]"
echo ""

# --- Settings ---
echo "Settings:"
check "settings.json is valid JSON" "jq empty '$CLAUDE_DIR/settings.json'"
check "settings.local.json exists" "[ -f '$CLAUDE_DIR/settings.local.json' ]"
if [ -f "$CLAUDE_DIR/settings.local.json" ]; then
  check "settings.local.json is valid JSON" "jq empty '$CLAUDE_DIR/settings.local.json'"
fi
check "Model is set to opus" "jq -e '.model | test(\"opus\")' '$CLAUDE_DIR/settings.json'"
check "Status line configured" "jq -e '.statusLine.command' '$CLAUDE_DIR/settings.json'"
check "Hooks configured" "jq -e '.hooks' '$CLAUDE_DIR/settings.json'"
check "Stop hook configured" "jq -e '.hooks.Stop' '$CLAUDE_DIR/settings.json'"
check "Setup hook configured" "jq -e '.hooks.Setup' '$CLAUDE_DIR/settings.json'"
echo ""

# --- Skills ---
echo "Skills:"
check "/review skill exists" "[ -f '$CLAUDE_DIR/skills/review/SKILL.md' ]"
check "/focus skill exists" "[ -f '$CLAUDE_DIR/skills/focus/SKILL.md' ]"
check "/threads skill exists" "[ -f '$CLAUDE_DIR/skills/threads/SKILL.md' ]"
check "/handoff skill exists" "[ -f '$CLAUDE_DIR/skills/handoff/SKILL.md' ]"
check "/verify skill exists" "[ -f '$CLAUDE_DIR/skills/verify/SKILL.md' ]"
check "/sync-to-dotfiles skill exists" "[ -f '$CLAUDE_DIR/skills/sync-to-dotfiles/SKILL.md' ]"
echo ""

# --- Hooks ---
echo "Hooks:"
check "guard-destructive.sh exists" "[ -f '$CLAUDE_DIR/hooks/guard-destructive.sh' ]"
check "guard-destructive.sh is executable" "[ -x '$CLAUDE_DIR/hooks/guard-destructive.sh' ]"
check "notify.sh exists" "[ -f '$CLAUDE_DIR/hooks/notify.sh' ]"
check "notify.sh is executable" "[ -x '$CLAUDE_DIR/hooks/notify.sh' ]"
check "session-journal.sh exists" "[ -f '$CLAUDE_DIR/hooks/session-journal.sh' ]"
check "session-journal.sh is executable" "[ -x '$CLAUDE_DIR/hooks/session-journal.sh' ]"
check "inject-context.sh exists" "[ -f '$CLAUDE_DIR/hooks/inject-context.sh' ]"
check "inject-context.sh is executable" "[ -x '$CLAUDE_DIR/hooks/inject-context.sh' ]"
check "brain-sync.sh exists" "[ -f '$CLAUDE_DIR/hooks/brain-sync.sh' ]"
check "brain-sync.sh is executable" "[ -x '$CLAUDE_DIR/hooks/brain-sync.sh' ]"
echo ""

# --- Brain ---
echo "Brain:"
check "brain/ symlink exists" "[ -L '$CLAUDE_DIR/brain' ] || [ -d '$CLAUDE_DIR/brain' ]"
check "brain/journal/ exists" "[ -d '$CLAUDE_DIR/brain/journal' ]"
check "brain/journal/handoffs/ exists" "[ -d '$CLAUDE_DIR/brain/journal/handoffs' ]"
check "brain/memory/ exists" "[ -d '$CLAUDE_DIR/brain/memory' ]"
check_warn "brain is a git repo" "[ -d '$CLAUDE_DIR/brain/.git' ]"
check_warn "threads.json exists" "[ -f '$CLAUDE_DIR/brain/journal/threads.json' ]"
check_warn "meta.yaml exists" "[ -f '$CLAUDE_DIR/brain/journal/meta.yaml' ]"
if [ -d "$CLAUDE_DIR/brain/.git" ]; then
  check_warn "brain has remote" "cd '$CLAUDE_DIR/brain' && git remote get-url origin"
fi
echo ""

# --- MCP Servers ---
echo "MCP Servers:"
CLAUDE_JSON="$HOME/.claude.json"
if [ -f "$CLAUDE_JSON" ]; then
  check "Linear MCP configured" "jq -e '.mcpServers[\"linear-server\"]' '$CLAUDE_JSON'"
else
  echo "  ✗ ~/.claude.json not found (run Claude Code once first)"
  fail=$((fail + 1))
fi
echo ""

# --- CLI Tools ---
echo "CLI Tools:"
check "jq installed" "command -v jq"
check "git installed" "command -v git"
check_warn "gh (GitHub CLI) installed" "command -v gh"
check_warn "claude CLI installed" "command -v claude"
echo ""

# --- Claude CLI checks (if available) ---
if command -v claude &>/dev/null; then
  echo "Claude CLI:"
  check_warn "MCP servers reachable" "claude mcp list 2>&1 | grep -q 'Connected'"
  echo ""
fi

# --- Directories ---
echo "Directories:"
check "skills/ exists" "[ -d '$CLAUDE_DIR/skills' ]"
check "hooks/ exists" "[ -d '$CLAUDE_DIR/hooks' ]"
check "agents/ exists" "[ -d '$CLAUDE_DIR/agents' ]"
check "projects/ exists (memory)" "[ -d '$CLAUDE_DIR/projects' ]"
echo ""

# --- Summary ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
total=$((pass + fail))
echo "Results: $pass/$total passed, $fail failed, $warn warnings"
if [ "$fail" -eq 0 ]; then
  echo "Setup looks good!"
else
  echo "Run ./claude/install-claude.sh to fix issues."
fi
