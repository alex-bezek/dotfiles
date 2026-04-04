---
name: focus
description: Load context for a topic or workstream. Describe what you want to work on in natural language — Claude finds relevant sessions, threads, memories, and tickets.
argument-hint: "<what you want to work on>"
user-invocable: true
allowed-tools: "Read Glob Grep Bash(cat:*) Bash(jq:*) Bash(ls:*) Bash(git log:*) Bash(git branch:*)"
---

# Focus on a Workstream

The user wants to load context for a specific area of work. They've described it in natural language via `$ARGUMENTS`. Your job is to find everything relevant across all available data sources and present a focused briefing.

## Data Sources to Search

Scan these in order. Each is a compact index — read the index, then selectively read detail files only for matches.

### 1. Work Threads (`~/.claude/brain/journal/threads.json`)
Scan all thread entries. Match against `$ARGUMENTS` by comparing with:
- Thread ID, project name, branch name
- Thread summary and last_task fields
Use fuzzy/semantic matching — "CD pipeline" should match a thread about "ArgoCD deployment rollouts" or a branch named "alex/deploy-pipeline".

### 2. Session Journal (`~/.claude/brain/journal/*.yaml`)
Scan recent daily journal files (last 7-14 days). Match session entries by:
- Task descriptions
- Branch names
- Project names
For matching sessions, note the dates, what tools were used, and whether there were open items.

### 3. Memory (`~/.claude/brain/memory/*/MEMORY.md`)
Scan memory index files across projects. Match entries by description.
Only read the actual memory files for strong matches.

### 4. Git History
In the current repo, check:
- `git branch -a` for branches matching the topic
- `git log --oneline` on matching branches for recent activity

### 5. Linear (if available and relevant)
If the topic sounds like it could map to Linear tickets, mention that the user can ask you to search Linear for related issues.

## Output

Present a focused briefing:

```
## Focus: <topic>

### Recent Activity
- <date>: <what happened> (branch: <branch>)
- <date>: <what happened>

### Current State
<synthesized summary of where things stand>

### Related Context
- Memory: <relevant memory entries>
- Branches: <matching branches>
- Threads: <matching work threads>

### Open Items
- <anything unfinished from matching sessions>
```

Keep it concise — this is a briefing, not a dump. Prioritize recent activity and current state over history.

## If nothing matches

If no data sources match `$ARGUMENTS`, say so and suggest:
- Being more specific about the work
- Checking `/threads` for available work threads
- Starting fresh (the journal will track this session automatically)

## Key Principle

You ARE the semantic search engine. The indexes are small enough to scan.
Match by meaning, not keywords. "CD work" matches "continuous deployment",
"deploy pipeline", "ArgoCD", "rollout strategy", etc.
