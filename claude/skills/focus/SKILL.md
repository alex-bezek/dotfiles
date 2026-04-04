---
name: focus
description: Load context for a topic or workstream. Searches project notes in the brain and git history.
argument-hint: "<what you want to work on>"
user-invocable: true
allowed-tools: "Read Glob Grep Bash(cat:*) Bash(yq:*) Bash(ls:*) Bash(git log:*) Bash(git branch:*)"
---

# Focus on a Workstream

The user wants to load context for a specific area of work. They've described it in natural language via `$ARGUMENTS`. Find everything relevant and present a focused briefing.

## Data Sources

### 1. Project Index (`~/.claude/brain/projects.yaml`)
Scan the index for matching projects. Match `$ARGUMENTS` against:
- Project ID and name
- Repo path and branch name
Use fuzzy/semantic matching — "API work" should match a project named "My Side Project API".

### 2. Project Notes (`~/.claude/brain/projects/<id>/`)
For matching projects, read their notes files. These contain status, decisions, next steps, architecture notes, etc.

### 3. Git History (current repo)
Check the current repo for relevant context:
- `git branch -a` for branches matching the topic
- `git log --oneline -20` on matching branches for recent activity

## Output

Present a focused briefing:

```
## Focus: <topic>

### Project Notes
<summarize what's in the brain for this project>

### Current State
<synthesized summary — branch state, what's done, what's open>

### Git Activity
<recent commits on relevant branches>

### Next Steps
<from the notes, what should be done next>
```

Keep it concise — this is a briefing, not a dump. Prioritize actionable context.

## If nothing matches

If no project notes or branches match `$ARGUMENTS`, say so and suggest:
- `/projects` to see tracked projects
- `/note <name>` to start tracking the current work
- Being more specific about what they're looking for

## Key Principle

You ARE the search engine. The index and notes are small enough to scan entirely.
Match by meaning, not keywords. "CD work" matches "continuous deployment",
"deploy pipeline", "ArgoCD", etc.
