# Claude Code Tips & Workflow Reference

A cheat sheet for building Claude Code habits. Organized by when you'd reach for each feature.

## Starting a Session

- **`/context`** — See what's loaded (CLAUDE.md files, MCP servers, context usage). MCP servers add tool definitions to every request, so check if they're eating context.
- **`/mcp`** — Check per-server context costs.
- **`/init`** — Generate a project-specific CLAUDE.md for a new repo. Good for onboarding Claude to a codebase.
- **Shift+Tab** — Cycle permission modes: auto-accept edits, plan mode, or delegate to agent. Useful for switching between exploration and implementation.

## During Work

- **`/review`** — Run the custom code review skill on your changes before committing.
- **`/compact <instructions>`** — Compress conversation context. Add instructions like "keep the test plan" to preserve specific info.
- **`/rewind`** — Restore conversation or code to a previous point. Can restore conversation only, code only, or both.
- **Voice input** — Hold Space to dictate. Useful for describing complex intent faster than typing.
- **Plan mode** — For complex tasks, switch to plan mode (Shift+Tab) to align on approach before implementation.
- **Double-Esc** — Restore code to its state before Claude's last edit (code-only rewind shortcut).

## Parallel Work

- **Git worktrees** — Sessions are tied to directories. Use `git worktree add` to run parallel Claude sessions on different branches.
- **Agent teams** — For large tasks, Claude can delegate to sub-agents that work in parallel using worktrees. Good for multi-file refactors, broad test coverage.
- **Prompt queue** — Queue multiple prompts while Claude is working. They execute in order after the current task finishes.

## Code Intelligence

- **gopls plugin** (enabled) — Gives Claude precise Go symbol navigation, jump-to-definition, and automatic error detection after edits. Much more accurate than grep-based exploration.

## Skills & Agents

- **Skills** (`/skill-name`) — User-invocable commands. Live in `~/.claude/skills/<name>/SKILL.md`. Support `$ARGUMENTS` for parameterized commands.
- **Sub-agents** — Claude auto-delegates to agents based on task description. Live in `~/.claude/agents/<name>.md`. Add "use proactively" to the description for automatic delegation.
- **Install community skills** — `npx anthropic/skills` to browse available skill packs.

## Hooks

- **Notification hook** (enabled) — Sends OS notification when Claude needs your attention. Useful in auto mode when you're doing other work.
- **PreToolUse hooks** — Block dangerous commands before they run. Can deny specific patterns.
- **PostToolUse hooks** — Auto-format, lint, or validate after edits.
- **Stop hooks** — Run checks after Claude finishes (e.g., verify tests pass).
- **Prompt-based hooks** — Use an LLM to evaluate whether output meets criteria.

## Memory

- **Auto memory** — Claude automatically remembers project context across sessions in `~/.claude/projects/<project>/memory/`.
- **`/memory`** — View or manage stored memories.
- Memory is per-project (scoped by working directory). Switching directories = different memory.

## Customization

- **`settings.local.json`** — Machine-specific overrides that aren't tracked in dotfiles.
- **Per-project settings** — `.claude/settings.json` in any repo for team-shared config.
- **Status line** — Customizable via `~/.claude/statusline.sh`. Receives JSON on stdin with model, context, cost, workspace info.
- **Spinner verbs** — Custom loading messages in `settings.json` under `spinnerVerbs`.

## Multi-Environment Notes

- Config is symlinked from dotfiles — `git pull` in dotfiles + re-run installer to update all environments.
- `settings.local.json` is per-machine (not tracked) for environment-specific overrides.
- MCP servers may differ per environment (e.g., AWS MCP only on EC2). Use `settings.local.json` or environment-specific `.mcp.json`.
- Voice input works in terminal but may have issues over SSH — use the desktop app or web app for voice in remote setups.

## Useful Commands

| Command | What it does |
|---------|-------------|
| `/review` | Code review (custom skill) |
| `/review security` | Security-focused review |
| `/compact` | Free up context window |
| `/context` | See what's using context |
| `/init` | Generate project CLAUDE.md |
| `/rewind` | Restore to checkpoint |
| `/mcp` | Check MCP server status |
| `/memory` | View/manage memories |
| `Shift+Tab` | Cycle permission modes |
| `Double-Esc` | Undo last code change |
| `Hold Space` | Voice input |
