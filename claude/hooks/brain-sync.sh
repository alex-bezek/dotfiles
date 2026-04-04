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
    # Fast-forward only, don't block session start on conflicts
    git pull --ff-only --quiet 2>/dev/null || true
    ;;
  push)
    # Stage everything, commit if changes, push
    git add -A 2>/dev/null || true
    if ! git diff --cached --quiet 2>/dev/null; then
      git commit -m "session $(date -u +%Y-%m-%dT%H:%M:%SZ)" --quiet 2>/dev/null || true
      git push --quiet 2>/dev/null || true
    fi
    ;;
esac
