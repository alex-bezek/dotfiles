---
name: threads
description: List all work threads — active, paused, and recently completed. Shows what you've been working on across projects.
user-invocable: true
allowed-tools: "Read Bash(cat:*) Bash(ls:*)"
---

# Work Threads

Show all tracked work threads from the session journal.

## Steps

1. Read `~/.claude/brain/journal/threads.json`
2. Display threads grouped by status (active first, then paused, then done)
3. For each thread show:
   - **ID** and **project/branch**
   - **Summary** (one line)
   - **Sessions**: count and last activity date
   - **Status**: active / paused / done

## Output format

```
Active:
  [argo-rollouts-plugin] ngrok-operator @ alex/argo-rollouts-plugin
    Phase 2 complete, testing in kind (5 sessions, last: 2026-04-04)

  [dotfiles-claude-setup] dotfiles @ master
    Claude Code portable config — self-improving system next (3 sessions, last: 2026-04-04)

Paused:
  (none)

Done:
  [prod-bug-auth-timeout] ngrok-monorepo @ alex/fix-auth-timeout
    Root caused to connection pool exhaustion (1 session, last: 2026-04-02)
```

If no threads.json exists, explain that the session journal hook needs to run first (end at least one session after setup).

Use `/resume <thread-id>` to load full context for a thread.
