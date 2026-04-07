#!/usr/bin/env bash
# Sync brain repo (private git repo holding project notes).
# Called by hooks and skills — not a hook itself.
#
# Usage: brain-sync.sh pull|push
#
# Pull: runs at session start (Setup hook)
# Push: runs after /note saves changes

BRAIN_DIR="$HOME/.claude/brain"

# Bail if brain repo not set up
if [ ! -d "$BRAIN_DIR/.git" ]; then
  exit 0
fi

cd "$BRAIN_DIR"

case "$1" in
  pull)
    # Try fast-forward first, fall back to rebase to handle divergence
    if ! git pull --ff-only --quiet 2>/dev/null; then
      # Commit any local changes before rebasing
      git add -A 2>/dev/null || true
      if ! git diff --cached --quiet 2>/dev/null; then
        git commit -m "session $(date -u +%Y-%m-%dT%H:%M:%SZ)" --quiet 2>/dev/null || true
      fi
      # Rebase local on top of remote — auto-resolve conflicts favoring both sides
      git pull --rebase --quiet 2>/dev/null || {
        # If rebase fails (real conflict), abort and warn but don't block session
        git rebase --abort 2>/dev/null || true
        echo "warning: brain sync has conflicts, run 'cd ~/.claude/brain && git pull' to resolve" >&2
      }
    fi
    ;;
  push)
    # Stage everything, commit if changes, push
    git add -A 2>/dev/null || true
    if ! git diff --cached --quiet 2>/dev/null; then
      git commit -m "session $(date -u +%Y-%m-%dT%H:%M:%SZ)" --quiet 2>/dev/null || true
    fi
    # Pull before push to avoid rejection from diverged remote
    git pull --rebase --quiet 2>/dev/null || {
      git rebase --abort 2>/dev/null || true
      echo "warning: brain sync push failed due to conflicts" >&2
      exit 1
    }
    git push --quiet 2>/dev/null || true
    ;;
esac
