---
name: handoff
description: Write a rich end-of-session handoff summary. Updates the work thread with current state and open items.
user-invocable: true
allowed-tools: "Read Write Bash(cat:*) Bash(jq:*) Bash(git:*) Glob"
---

# Session Handoff

Write a detailed handoff document capturing the current session's work, decisions, and next steps. This updates the work thread so the next session (or a teammate) can pick up seamlessly.

## Steps

### 1. Reflect on this session

Based on your conversation context, summarize:
- **Goal**: What were we trying to accomplish?
- **Approach**: What approach was taken and why?
- **Key decisions**: What choices were made? What was considered and rejected?
- **What's done**: What was completed and tested?
- **What's open**: What's unfinished, untested, or needs follow-up?
- **Next steps**: What should the next session do first?

### 2. Find the thread

Detect the current project and branch. Look up the thread in `~/.claude/brain/journal/threads.json`.

### 3. Write handoff file

Write the handoff to `~/.claude/brain/journal/handoffs/<thread-id>-latest.md`:

```markdown
# Handoff: <thread-id>
**Date**: YYYY-MM-DD
**Project**: <project> @ <branch>

## Goal
<one sentence>

## What was done
- <bullet points>

## Key decisions
- <bullet points with reasoning>

## Open items
- <bullet points>

## Next steps
1. <prioritized list>
```

### 4. Update thread summary

Update the thread's `summary` field in `~/.claude/brain/journal/threads.json` using jq to reflect the current state (not the original task description).

### 5. Confirm

Tell the user the handoff was written and where to find it.
