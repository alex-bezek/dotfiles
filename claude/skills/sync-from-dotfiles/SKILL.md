---
name: sync-from-dotfiles
description: Pull latest dotfiles and refresh local Claude Code config. Use when dotfiles repo has been updated.
user-invocable: true
allowed-tools: "Bash(bash:*) Bash(git:*) Bash(ls:*) Read Glob AskUserQuestion"
---

# Sync Dotfiles to Local Config

Pull the latest dotfiles and re-apply Claude Code configuration.

## Steps

### 1. Find the dotfiles repo

Look for the claude dotfiles directory. Check in order:
- `~/code/dotfiles/claude/`
- The directory that `~/.claude/CLAUDE.md` symlinks to (via `readlink`)
- Ask the user if not found

### 2. Check for local changes

Before pulling, check if there are local changes in `~/.claude/` that would be overwritten:
- Compare `~/.claude/settings.local.json` against the repo template
- Check for any non-symlinked files that have been modified

If there are local changes that would be lost, warn the user and offer to run `/sync-to-dotfiles` first.

### 3. Pull and refresh

Run `bash <dotfiles-repo>/claude/refresh.sh` which will:
- `git pull --ff-only` the dotfiles repo
- Re-run the installer

### 4. Verify

Run `bash <dotfiles-repo>/claude/verify.sh` and report results.

### 5. Summary

Report what changed:
- Files updated
- New skills/hooks/agents added
- Environment-specific settings applied
- Any warnings from the installer
