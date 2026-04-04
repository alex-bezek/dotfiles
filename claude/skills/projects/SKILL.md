---
name: projects
description: List all tracked projects in the brain with status and last activity.
user-invocable: true
allowed-tools: "Read Bash(cat:*) Bash(ls:*) Bash(stat:*) Bash(git:*) Bash(yq:*) Glob"
---

# List Tracked Projects

Show all projects the user has notes on in their brain.

## Steps

1. Read `~/.claude/brain/projects.yaml`
2. For each project entry, display:
   - **Name** and ID
   - **Status** (active / paused / done)
   - **Repo** and **branch** (if set)
   - **Last updated** date
3. Group by status: active first, then paused, then done
4. If the index is empty or missing, check `~/.claude/brain/projects/` for any folders and mention them as unindexed

## Output format

Keep it scannable:

```
## Tracked Projects

**Active**
- **My Side Project API** (my-api) — feature/auth — updated Apr 4
- **Dotfiles Setup** (dotfiles) — master — updated Apr 3

**Paused**
- **Old Thing** (old-thing) — updated Mar 20

Use /focus <name> to load context, /note <name> to update notes.
```

## If no projects

Say there are no tracked projects yet and suggest `/note <project-name>` to start tracking one.
