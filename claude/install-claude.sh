#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_JSON="$HOME/.claude.json"

# --- Environment detection ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  CLAUDE_ENV="macos"
elif [[ -n "$CODESPACES" ]]; then
  CLAUDE_ENV="codespaces"
else
  CLAUDE_ENV="linux"
fi

echo "Setting up Claude Code (env: $CLAUDE_ENV)..."

# --- Install Claude Code CLI ---
if ! command -v claude &> /dev/null; then
  echo "  Installing Claude Code CLI..."
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "  ✅ Claude Code CLI already installed"
fi

# --- Ensure ~/.claude.json exists and mark onboarding complete ---
if [ ! -f "$CLAUDE_JSON" ]; then
  echo '{}' > "$CLAUDE_JSON"
fi
if command -v jq &> /dev/null; then
  tmp=$(mktemp)
  jq '.hasCompletedOnboarding = true' "$CLAUDE_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
  echo "  Marked onboarding complete"
fi

# --- Helper: force-symlink (removes existing symlink or backs up real file) ---
force_link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.backup"
  fi
  ln -sf "$src" "$dst"
}

# --- Directories ---
mkdir -p "$CLAUDE_DIR"/{skills,agents,hooks}

# --- Brain repo ---
BRAIN_REPO="git@github.com:alex-bezek/claude-brain.git"
BRAIN_LOCAL="$HOME/code/claude-brain"
BRAIN_LINK="$CLAUDE_DIR/brain"

if [ ! -d "$BRAIN_LOCAL" ]; then
  # Pre-add GitHub's SSH host key so the clone doesn't prompt interactively
  mkdir -p "$HOME/.ssh"
  ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true

  git clone "$BRAIN_REPO" "$BRAIN_LOCAL" --quiet 2>/dev/null || \
    echo "  ⚠  Could not clone brain repo — clone manually: git clone $BRAIN_REPO $BRAIN_LOCAL"
fi

if [ -d "$BRAIN_LOCAL" ]; then
  mkdir -p "$BRAIN_LOCAL/projects"
  force_link "$BRAIN_LOCAL" "$BRAIN_LINK"
  echo "  Linked brain → $BRAIN_LOCAL"
else
  mkdir -p "$CLAUDE_DIR/brain/projects"
  echo "  Using local brain (clone $BRAIN_REPO for cross-env sync)"
fi

# --- Symlink dotfiles ---
force_link "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
force_link "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"

chmod +x "$SCRIPT_DIR/statusline.sh"
force_link "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh"

echo "  Linked CLAUDE.md, settings.json, statusline.sh"

# --- Skills ---
if [ -d "$SCRIPT_DIR/skills" ]; then
  for dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    force_link "$dir" "$CLAUDE_DIR/skills/$name"
    echo "  Linked skill: $name"
  done
fi

# --- Agents ---
if [ -d "$SCRIPT_DIR/agents" ]; then
  for file in "$SCRIPT_DIR/agents"/*.md; do
    [ -f "$file" ] || continue
    name=$(basename "$file")
    force_link "$file" "$CLAUDE_DIR/agents/$name"
    echo "  Linked agent: $name"
  done
fi

# --- Hooks ---
if [ -d "$SCRIPT_DIR/hooks" ]; then
  for file in "$SCRIPT_DIR/hooks"/*.sh; do
    [ -f "$file" ] || continue
    name=$(basename "$file")
    chmod +x "$file"
    force_link "$file" "$CLAUDE_DIR/hooks/$name"
    echo "  Linked hook: $name"
  done
fi

# --- Environment-specific settings.local.json ---
if [ -f "$SCRIPT_DIR/settings.local.$CLAUDE_ENV.json" ]; then
  cp "$SCRIPT_DIR/settings.local.$CLAUDE_ENV.json" "$CLAUDE_DIR/settings.local.json"
  echo "  Deployed settings.local.json for $CLAUDE_ENV"
fi

# --- MCP Servers ---
if command -v jq &> /dev/null && [ -f "$CLAUDE_JSON" ]; then
  tmp=$(mktemp)
  jq '
    .mcpServers["linear-server"] //= {"type": "http", "url": "https://mcp.linear.app/mcp"} |
    .mcpServers["playwright"] //= {"type": "stdio", "command": "npx", "args": ["@playwright/mcp@latest"]}
  ' "$CLAUDE_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
  echo "  Ensured MCP servers configured"
fi

# --- Plugins ---
if command -v claude &> /dev/null && command -v jq &> /dev/null; then
  echo "  Installing plugins..."
  plugins=$(jq -r '.enabledPlugins // {} | keys[]' "$SCRIPT_DIR/settings.json" 2>/dev/null)
  for plugin in $plugins; do
    if claude plugin install "$plugin" 2>/dev/null; then
      echo "  Installed plugin: $plugin"
    else
      echo "  ⚠  Plugin failed: $plugin (install manually: claude plugin install $plugin)"
    fi
  done
fi

# --- Tool warnings ---
for tool in gh jq; do
  command -v "$tool" &> /dev/null || echo "  ⚠  $tool not found — install for full functionality"
done

echo ""
echo "✅ Claude Code setup complete (env: $CLAUDE_ENV)"
