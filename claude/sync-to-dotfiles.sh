#!/usr/bin/env bash
set -e

# Sync local Claude Code config changes back to the dotfiles repo.
# Use this after editing files in ~/.claude/ to capture changes in version control.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Syncing Claude Code config back to dotfiles..."
echo "  From: $CLAUDE_DIR"
echo "  To:   $SCRIPT_DIR"

changed=0

# --- CLAUDE.md ---
# Only sync if the local file is NOT a symlink (means it was edited directly)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && [ ! -L "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$CLAUDE_DIR/CLAUDE.md" "$SCRIPT_DIR/CLAUDE.md"
  echo "  Synced CLAUDE.md (was modified locally)"
  changed=$((changed + 1))
fi

# --- settings.local.json ---
# Detect environment to know which template to update
if [[ "$OSTYPE" == "darwin"* ]]; then
  CLAUDE_ENV="macos"
elif [[ -n "$CODESPACES" ]]; then
  CLAUDE_ENV="codespaces"
else
  CLAUDE_ENV="linux"
fi

if [ -f "$CLAUDE_DIR/settings.local.json" ]; then
  target="$SCRIPT_DIR/settings.local.$CLAUDE_ENV.json"
  if ! diff -q "$CLAUDE_DIR/settings.local.json" "$target" &>/dev/null 2>&1; then
    cp "$CLAUDE_DIR/settings.local.json" "$target"
    echo "  Synced settings.local.json → settings.local.$CLAUDE_ENV.json"
    changed=$((changed + 1))
  fi
fi

# --- Skills (non-symlinked only) ---
if [ -d "$CLAUDE_DIR/skills" ]; then
  for skill_dir in "$CLAUDE_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    # Only sync skills that exist in dotfiles (don't pull in project-specific ones)
    if [ -d "$SCRIPT_DIR/skills/$skill_name" ] && [ ! -L "$skill_dir" ]; then
      rm -rf "$SCRIPT_DIR/skills/$skill_name"
      cp -r "$skill_dir" "$SCRIPT_DIR/skills/$skill_name"
      echo "  Synced skill: $skill_name (was modified locally)"
      changed=$((changed + 1))
    fi
  done
fi

# --- Hooks (non-symlinked only) ---
if [ -d "$CLAUDE_DIR/hooks" ]; then
  for hook_file in "$CLAUDE_DIR/hooks"/*.sh; do
    [ -f "$hook_file" ] || continue
    hook_name=$(basename "$hook_file")
    if [ -f "$SCRIPT_DIR/hooks/$hook_name" ] && [ ! -L "$hook_file" ]; then
      cp "$hook_file" "$SCRIPT_DIR/hooks/$hook_name"
      echo "  Synced hook: $hook_name (was modified locally)"
      changed=$((changed + 1))
    fi
  done
fi

if [ "$changed" -eq 0 ]; then
  echo ""
  echo "Nothing to sync — all config files are symlinks pointing to dotfiles."
else
  echo ""
  echo "Synced $changed file(s). Review changes with:"
  echo "  cd $SCRIPT_DIR && git diff"
fi
