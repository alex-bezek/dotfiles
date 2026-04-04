#!/usr/bin/env bash
set -e

# Refresh Claude Code config from dotfiles.
# Use this after pulling dotfiles updates, or to re-apply config on an existing setup.
# This is just a convenience wrapper around install-claude.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pull latest if we're in a git repo
if git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Pulling latest dotfiles..."
  git -C "$SCRIPT_DIR/.." pull --ff-only 2>/dev/null || echo "  (pull skipped — not on a tracking branch or has local changes)"
  echo ""
fi

exec bash "$SCRIPT_DIR/install-claude.sh"
