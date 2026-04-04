---
name: sync-to-dotfiles
description: Ensure the dotfiles repo is up to date with all Claude Code config changes. Shows full git status, diffs, and new files before committing.
argument-hint: "[--pr]"
user-invocable: true
allowed-tools: "Bash(diff:*) Bash(git:*) Bash(bash:*) Bash(cat:*) Bash(ls:*) Bash(gh:*) Read Glob Grep AskUserQuestion"
---

# Sync Local Config to Dotfiles

Ensure the dotfiles repo captures all Claude Code config changes — modified files, new files, and any copied (non-symlinked) config that may have drifted.

## Steps

### 1. Find the dotfiles repo

Look for the claude dotfiles directory. Check in order:
- `~/code/dotfiles/claude/`
- The directory that `~/.claude/CLAUDE.md` symlinks to (via `readlink`)
- Ask the user if not found

### 2. Sync copied files first

Some files are copied (not symlinked) and may have drifted from the repo:
- `~/.claude/settings.local.json` — compare against `settings.local.<env>.json` template in the repo

If the local copy differs from the repo template, show the diff and ask whether to:
- Sync the local changes back to the repo template
- Or revert local to match the repo

### 3. Show full dotfiles repo status

Run `git status` and `git diff` in the dotfiles repo to show the **complete picture**:
- **Modified files**: show the diff for each
- **Untracked files**: list them all, including new files in subdirectories (use `git status -u`)
- **New files**: show their contents (or a summary if large) so the user can review what's being added

For any file that looks like a one-off experiment, debug artifact, or contains secrets — call it out explicitly.

### 4. Ask before committing

Present a clear summary of everything that will be committed:
- Modified files (with brief description of what changed)
- New files being added
- Deleted files

Use the `AskUserQuestion` tool to confirm. Offer options like "Commit all", "Commit (let me pick files)", or "Cancel". Don't wait for the user to type — give them a clickable confirmation.

### 5. Commit and optionally PR

If approved, stage and commit with a descriptive message about what config changed.

If `$ARGUMENTS` contains `--pr`:
- Create a feature branch
- Commit and push
- Open a PR with a summary of changes

Otherwise, commit to the current branch and let the user push when ready.

## Important

- Always show the full git status including untracked files — new skills, hooks, and config files are just as important as modifications
- Never commit without showing the user what's included
- Call out anything that looks like it shouldn't be committed (debug flags, temp values, secrets, `.backup` files)
- If there's a `random-ai-notes.md` or similar scratch file, flag it for the user's attention
