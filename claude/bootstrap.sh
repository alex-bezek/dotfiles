#!/usr/bin/env bash
# Bootstrap Claude Code setup from scratch.
# Idempotent — safe to re-run on an existing machine.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/alex-bezek/dotfiles/master/claude/bootstrap.sh | bash
#   # or just:
#   ~/code/dotfiles/claude/bootstrap.sh

set -e

CODE_DIR="$HOME/code"
DOTFILES_REPO="https://github.com/alex-bezek/dotfiles.git"
DOTFILES_DIR="$CODE_DIR/dotfiles"
BRAIN_REPO="git@github.com:alex-bezek/claude-brain.git"
BRAIN_DIR="$CODE_DIR/claude-brain"

echo "=== Claude Code Bootstrap ==="
echo ""

# --- Prerequisites ---
# shellcheck disable=SC2043 # single-element loop is intentional, more prereqs may be added
for cmd in git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is required but not installed."
    exit 1
  fi
done

if ! command -v jq &>/dev/null; then
  echo "⚠  jq not found — installing..."
  if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &>/dev/null; then
    brew install jq
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq jq
  else
    echo "  Install jq manually: https://jqlang.github.io/jq/download/"
  fi
fi

# --- Ensure ~/code exists ---
mkdir -p "$CODE_DIR"

# --- Clone or update dotfiles ---
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "Dotfiles repo exists, pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only --quiet 2>/dev/null || true
else
  echo "Cloning dotfiles..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" --quiet
fi

# --- Clone or update brain (private — may fail without SSH key) ---
if [ -d "$BRAIN_DIR/.git" ]; then
  echo "Brain repo exists, pulling latest..."
  git -C "$BRAIN_DIR" pull --ff-only --quiet 2>/dev/null || true
else
  echo "Cloning brain repo (private)..."
  git clone "$BRAIN_REPO" "$BRAIN_DIR" --quiet 2>/dev/null || {
    echo "⚠  Could not clone brain repo (need SSH key for github.com)"
    echo "  Clone manually: git clone $BRAIN_REPO $BRAIN_DIR"
    echo "  Then re-run this script."
    echo ""
    echo "  Continuing without brain sync (local-only mode)..."
  }
fi

# --- Run installer ---
echo ""
bash "$DOTFILES_DIR/claude/install-claude.sh"

# --- Verify ---
echo ""
echo "Running verification..."
echo ""
bash "$DOTFILES_DIR/claude/verify.sh"

echo ""
echo "Bootstrap complete. Run 'claude' to start a session."
