---
name: note
description: Save or update project notes in the brain. Captures status, decisions, and next steps for long-running projects.
argument-hint: "[project-name]"
user-invocable: true
allowed-tools: "Read Write Bash(cat:*) Bash(jq:*) Bash(yq:*) Bash(ls:*) Bash(git:*) Bash(date:*) Bash(~/.claude/hooks/brain-sync.sh:*) Glob"
---

# Save Project Notes

The user wants to capture notes about a project they're working on. This could be status, decisions, what's next, architecture notes, or anything they want to remember across sessions.

## Determine the project

1. If `$ARGUMENTS` is provided, use it as the project name/identifier
2. Otherwise, infer from the current working directory (basename of cwd)
3. Sanitize to a valid directory name: lowercase, hyphens for spaces, no special chars

## Check existing notes

- Read `~/.claude/brain/projects.yaml` for the project index
- Check if `~/.claude/brain/projects/<project>/` exists
- If it exists, read existing notes to understand what's already captured

## Write or update notes

**If new project:** Create the folder and a `notes.md` file. Based on conversation context, write useful notes. Include whatever is relevant:
- What the project is
- Current status / state of the branch
- Key decisions made and why
- What's next / open items
- Gotchas, blockers, or things to remember

**If existing project:** Read the current notes and update them. Don't rewrite from scratch — merge new information in. Add to existing sections, update status, mark completed items.

**For large projects:** If the notes are getting long or cover distinct topics, split into multiple files in the project folder (e.g., `architecture.md`, `api-design.md`). Use your judgment.

### Writing style

Write like notes to your future self. Be direct, skip fluff. Use bullet points. Include enough context that someone returning after a week can get oriented in 30 seconds.

Don't use a rigid template. Let the content dictate the structure.

## Update the index

After writing notes, update `~/.claude/brain/projects.yaml`:

```yaml
projects:
  - id: my-api
    name: My Side Project API
    status: active          # active, paused, done
    repo: ~/code/my-api     # if known
    branch: feature/auth    # if known
    updated: 2026-04-04     # today's date
```

- If the project already exists in the index, update `status`, `branch`, and `updated`
- If new, append an entry
- Use `yq` if available, otherwise write with careful string manipulation
- The `name` field should be a human-readable title (infer from context or ask)
- `repo` and `branch` are optional — include if you know them

## Sync to remote

Run `~/.claude/hooks/brain-sync.sh push` to commit and push changes.

## Confirm

Tell the user what was saved and where. Keep it brief.
