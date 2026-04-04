#!/usr/bin/env bash
# Claude Code status line — shows model, git branch, changed files, context%, cost
input=$(cat)

# Debug: uncomment to log raw JSON and inspect what Claude Code sends
# echo "$input" >> /tmp/claude-statusline-debug.json

# Shorten model name: "Opus 4.6 (1M context)" → "Opus 4.6"
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"' | sed 's/ *(.*//')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(printf '%.2f' "$(echo "$input" | jq -r '.cost.total_cost_usd // 0')")

# Git info (if in a repo)
# NOTE: git status --porcelain can be slow in large repos. If this causes lag,
# consider removing the changed file count or caching it.
BRANCH=""
CHANGES=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  UNSTAGED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$UNSTAGED" -gt 0 ] 2>/dev/null; then
    CHANGES="${UNSTAGED} changed"
  fi
fi

# Context bar (clean ascii style)
FILLED=$((PCT / 5))
EMPTY=$((20 - FILLED))
BAR="["
for i in $(seq 1 $FILLED); do BAR="${BAR}#"; done
for i in $(seq 1 $EMPTY); do BAR="${BAR}-"; done
BAR="${BAR}]"

# Build output
OUT="[${MODEL}]"
if [ -n "$BRANCH" ]; then
  OUT="${OUT} ${BRANCH}"
  if [ -n "$CHANGES" ]; then
    OUT="${OUT} (${CHANGES})"
  fi
  OUT="${OUT} |"
fi
OUT="${OUT} ${BAR} ${PCT}% | \$${COST}"

echo "$OUT"
