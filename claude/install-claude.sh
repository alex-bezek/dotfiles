#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# --- Environment detection ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  CLAUDE_ENV="macos"
elif [[ -n "$CODESPACES" ]]; then
  CLAUDE_ENV="codespaces"
else
  CLAUDE_ENV="linux"
fi

echo "Setting up Claude Code dotfiles..."
echo "  Source: $SCRIPT_DIR"
echo "  Target: $CLAUDE_DIR"
echo "  Environment: $CLAUDE_ENV"

# Ensure base directories exist
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/hooks"

# --- Brain repo (private, holds journal + memory) ---
BRAIN_REPO="git@github.com:alex-bezek/claude-brain.git"
BRAIN_LOCAL="$HOME/code/claude-brain"
BRAIN_LINK="$CLAUDE_DIR/brain"

if [ ! -d "$BRAIN_LOCAL" ]; then
  echo "  Cloning brain repo..."
  git clone "$BRAIN_REPO" "$BRAIN_LOCAL" --quiet 2>/dev/null || {
    echo "  ⚠  Could not clone brain repo — clone manually: git clone $BRAIN_REPO $BRAIN_LOCAL"
  }
fi

if [ -d "$BRAIN_LOCAL" ]; then
  # Ensure brain directory structure
  mkdir -p "$BRAIN_LOCAL/journal/handoffs" "$BRAIN_LOCAL/memory"
  # Create symlink
  if [ -L "$BRAIN_LINK" ]; then
    rm "$BRAIN_LINK"
  elif [ -d "$BRAIN_LINK" ]; then
    echo "  ⚠  $BRAIN_LINK is a real directory — move it aside before re-running"
  fi
  [ ! -e "$BRAIN_LINK" ] && ln -sf "$BRAIN_LOCAL" "$BRAIN_LINK"
  echo "  Linked brain → $BRAIN_LOCAL"
else
  # No brain repo — create local directories as fallback
  mkdir -p "$CLAUDE_DIR/brain/journal/handoffs" "$CLAUDE_DIR/brain/memory"
  echo "  Using local brain (no sync — clone $BRAIN_REPO for cross-env sync)"
fi

# --- CLAUDE.md ---
# Symlink global instructions
if [ -L "$CLAUDE_DIR/CLAUDE.md" ]; then
  rm "$CLAUDE_DIR/CLAUDE.md"
elif [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  echo "  Backing up existing CLAUDE.md to CLAUDE.md.backup"
  mv "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup"
fi
ln -sf "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  Linked CLAUDE.md"

# --- settings.json ---
# Overwrite entirely — dotfiles is source of truth
# Use settings.local.json for machine-specific overrides
if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
  echo "  Backing up existing settings.json to settings.json.backup"
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup"
fi
if [ -L "$CLAUDE_DIR/settings.json" ]; then
  rm "$CLAUDE_DIR/settings.json"
fi
ln -sf "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
echo "  Linked settings.json"

# --- statusline.sh ---
chmod +x "$SCRIPT_DIR/statusline.sh"
if [ -L "$CLAUDE_DIR/statusline.sh" ]; then
  rm "$CLAUDE_DIR/statusline.sh"
fi
ln -sf "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh"
echo "  Linked statusline.sh"

# --- Skills ---
# Symlink any skill directories from dotfiles, preserving existing ones
if [ -d "$SCRIPT_DIR/skills" ]; then
  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target="$CLAUDE_DIR/skills/$skill_name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "  Skipping skill '$skill_name' — already exists (not a symlink)"
    else
      [ -L "$target" ] && rm "$target"
      ln -sf "$skill_dir" "$target"
      echo "  Linked skill: $skill_name"
    fi
  done
fi

# --- Hooks ---
# Symlink hook scripts from dotfiles
if [ -d "$SCRIPT_DIR/hooks" ]; then
  for hook_file in "$SCRIPT_DIR/hooks"/*.sh; do
    [ -f "$hook_file" ] || continue
    hook_name=$(basename "$hook_file")
    target="$CLAUDE_DIR/hooks/$hook_name"
    [ -L "$target" ] && rm "$target"
    chmod +x "$hook_file"
    ln -sf "$hook_file" "$target"
    echo "  Linked hook: $hook_name"
  done
fi

# --- settings.local.json ---
# Environment-specific overrides — dotfiles is source of truth, always overwrite
LOCAL_SETTINGS="$CLAUDE_DIR/settings.local.json"
if [ -f "$SCRIPT_DIR/settings.local.$CLAUDE_ENV.json" ]; then
  cp "$SCRIPT_DIR/settings.local.$CLAUDE_ENV.json" "$LOCAL_SETTINGS"
  echo "  Deployed settings.local.json for $CLAUDE_ENV"
else
  echo "  No settings.local.$CLAUDE_ENV.json template found, skipping"
fi

# --- MCP Servers ---
# Merge MCP server config into ~/.claude.json (runtime state file — never overwrite)
CLAUDE_JSON="$HOME/.claude.json"
if command -v jq &> /dev/null; then
  if [ -f "$CLAUDE_JSON" ]; then
    # Linear MCP server
    if ! jq -e '.mcpServers["linear-server"]' "$CLAUDE_JSON" &>/dev/null; then
      tmp=$(mktemp) && trap "rm -f '$tmp'" EXIT
      jq '.mcpServers["linear-server"] = {"type": "http", "url": "https://mcp.linear.app/mcp"}' "$CLAUDE_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
      echo "  Added Linear MCP server (run 'claude mcp' to authenticate)"
    else
      echo "  Linear MCP server already configured"
    fi
  else
    echo "  Skipping MCP setup — ~/.claude.json not found (run Claude Code once first)"
  fi
else
  echo "  Skipping MCP setup — jq not installed"
fi

# --- CLI tool checks ---
# Warn about tools Claude Code benefits from
for tool in gh jq; do
  if ! command -v "$tool" &> /dev/null; then
    echo "  ⚠  $tool not found — install it for full Claude Code functionality"
  fi
done

# --- Agents ---
# Symlink any agent files from dotfiles, preserving existing ones
if [ -d "$SCRIPT_DIR/agents" ]; then
  for agent_file in "$SCRIPT_DIR/agents"/*.md; do
    [ -f "$agent_file" ] || continue
    agent_name=$(basename "$agent_file")
    target="$CLAUDE_DIR/agents/$agent_name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "  Skipping agent '$agent_name' — already exists (not a symlink)"
    else
      [ -L "$target" ] && rm "$target"
      ln -sf "$agent_file" "$target"
      echo "  Linked agent: $agent_name"
    fi
  done
fi

echo ""
echo "Claude Code dotfiles installed. (environment: $CLAUDE_ENV)"
echo ""
echo "Preserved (not touched):"
echo "  ~/.claude.json (runtime state, MCP servers merged in)"
echo "  ~/.claude/projects/ (memory)"
echo ""
echo "To add environment-specific overrides:"
echo "  Edit claude/settings.local.$CLAUDE_ENV.json in your dotfiles repo, then re-run installer"
