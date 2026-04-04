---
name: verify
description: Verify Claude Code dotfiles setup is correct. Runs checks on symlinks, settings, skills, hooks, MCP servers, and CLI tools.
user-invocable: true
allowed-tools: "Bash(bash:*) Read Glob"
---

# Verify Claude Code Setup

Run the verification script and interpret the results.

## Steps

1. Run `bash ~/.claude/verify.sh` (or find it via the dotfiles repo at `~/code/dotfiles/claude/verify.sh`)
2. Report the results clearly
3. If there are failures, explain what's wrong and how to fix each one
4. If everything passes, confirm the setup is healthy

## If verify.sh is not found

Fall back to manual checks:
- Check symlinks exist: `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/statusline.sh`
- Check settings.json is valid JSON with `jq empty`
- Check skills exist: `~/.claude/skills/review/SKILL.md`
- Check hooks are executable: `~/.claude/hooks/guard-destructive.sh`, `~/.claude/hooks/notify.sh`
- Check CLI tools: `jq`, `git`, `gh`, `claude`
- Check MCP: `jq '.mcpServers' ~/.claude.json`
