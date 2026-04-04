# Claude Code Configuration

Portable Claude Code setup managed via dotfiles. Run `./install-claude.sh` to symlink everything into `~/.claude/`.

## What's Configured

### Global Instructions (`CLAUDE.md`)

Applied to every Claude Code session. Sets defaults for:
- **Communication style** — concise, questions up front, verification plans
- **Code style** — no unnecessary abstractions, no drive-by improvements
- **Go** — table-driven tests, proper context passing, error wrapping
- **Git** — "why" not "what" commit messages, feature branches

### Settings (`settings.json`)

| Setting | Value | Notes |
|---------|-------|-------|
| Model | `opus[1m]` | Opus with 1M context window |
| Default mode | `auto` | Auto-accept most tool calls |
| LSP Plugin | `gopls` | Go language server for symbol navigation and error detection |
| Voice | Enabled | Hold Space to dictate |
| Status line | Custom script | Shows model, git branch, changed files, context %, cost |
| Notifications | Platform-aware | macOS: system notification, Linux: `notify-send`, fallback: terminal bell |

Environment-specific overrides are in `settings.local.<env>.json` (see [Environments](#environments) below).

### Status Line (`statusline.sh`)

Displays: `[Opus] branch-name (N changed) | [####----------------] 20% | $1.47`

- Model name (shortened)
- Current git branch + uncommitted file count
- Context window usage bar (20-wide ASCII)
- Session cost (2 decimal places)

### Skills

| Skill | Invocation | Description |
|-------|-----------|-------------|
| `/review` | `/review`, `/review path/to/file.go`, `/review security` | Go code review — correctness, patterns, K8s conventions, safety |
| `/verify` | `/verify` | Run setup verification checks (symlinks, settings, tools, MCP) |
| `/sync-to-dotfiles` | `/sync-to-dotfiles`, `/sync-to-dotfiles --pr` | Show diff of local vs dotfiles repo, sync changes back. With `--pr`, creates a PR. |
| `/sync-from-dotfiles` | `/sync-from-dotfiles` | Pull latest dotfiles and refresh local config. Warns about local changes first. |
| `/focus` | `/focus CD pipeline`, `/focus terraform VPC` | Load context for a workstream by natural language description. Searches threads, journal, memory, git branches. |
| `/threads` | `/threads` | List all tracked work threads with status and last activity. |
| `/handoff` | `/handoff` | Write a rich end-of-session summary. Updates work thread state. |
| `/resume` | `/resume <topic>` | Alias for `/focus`. |

### Hooks

| Event | Script | What it does |
|-------|--------|-------------|
| `Notification` | `notify.sh` | Sends OS-native notification when Claude needs attention (macOS `osascript`, Linux `notify-send`, fallback `\a` bell) |
| `PreToolUse` | `guard-destructive.sh` | Blocks `git push --force`, `git reset --hard`, `git clean -f`, and dangerous `rm -rf` targets. Suggests safer alternatives. |
| `Stop` | `session-journal.sh` | Writes session journal entry (task, tools, corrections), updates work threads, increments review counter. |
| `Setup` | `inject-context.sh` | Shows recent work threads at session start. Nudges `/self-review` when due. |

### MCP Servers

| Server | Type | Managed by | What it does |
|--------|------|-----------|-------------|
| Linear (`linear-server`) | HTTP | Installer (merged into `~/.claude.json`) | Issue tracking — list, create, update Linear issues/projects/cycles |
| Slack (`claude.ai Slack`) | Built-in | Claude Code (auto-discovered) | Read channels/DMs, search messages, send messages |

**Authentication**: Both servers require OAuth. Use them in a session and you'll be prompted to authenticate via browser, or run `/mcp` to manage connections.

**`gh` CLI**: Used for GitHub operations (PRs, issues, checks) via Bash tool. Installed by the main `install.sh` on macOS (`brew`) and Linux (`apt`). The Claude installer warns if it's missing but doesn't install it.

#### Future MCP Servers to Consider

| Server | Why | Priority |
|--------|-----|----------|
| Sentry | Error tracking — investigate production errors in context | Medium |
| Datadog | Observability — check dashboards/monitors when debugging perf | Medium |
| AWS | Cloud resource management for EC2 dev workflows | Medium |
| Buildkite | CI/CD — check build status, trigger pipelines | Medium |
| Notion | Team docs — reference runbooks and design docs | Low |
| GitHub (MCP) | Direct tool access vs `gh` CLI — evaluate if it adds value over Bash | Low |
| Context7 | Up-to-date library docs in context | Low |
| ngrok API/Docs | Internal tooling — wait for official MCP support (mintlify?) | TBD |
| Figma | Design specs — useful if doing frontend work | Low |
| PostHog | Analytics — product usage data | Low |

### Future Enhancements

**Skills & Agents**
- Sub-agents: test writer, docs writer, build validator, code architect, on-call guide
- Agent teams for large multi-file tasks
- Skill creator skill (`npx anthropic/skills` skill packs)

**Plugins to Evaluate**
- `commit-commands` — git commit workflows including push and PR creation
- `pr-review-toolkit` — specialized agents for PR review
- `context-mode` (`mksglu/context-mode`) — context management

**Hooks & Automation**
- Git commit hooks integration for agent harness engineering (save + describe + validate)
- PostToolUse hook for repo-specific formatters (per-project, not global)

**Environment & Platform**
- Voice input across Mac / VM / Codespaces (currently Mac-only)
- Install Claude Code in dev containers and Codespaces definitions
- Screenshots over SSH (known limitation)
- Claude Code online (`claude.ai/code`) for repo interaction

**Other**
- Claude Desktop "Cowork" feature — investigate use case
- Customize spinner verbs further
- Propose pushing config into shared team repos once patterns stabilize

### Environments

The installer detects the environment and deploys the matching `settings.local.<env>.json`:

| Environment | Detection | Overrides |
|-------------|-----------|-----------|
| `macos` | `$OSTYPE == darwin*` | Full features (voice, notifications) |
| `codespaces` | `$CODESPACES` set | Voice disabled |
| `linux` | Default | Voice disabled |

To customize an environment, edit `settings.local.<env>.json` in the dotfiles repo and re-run the installer. Project-specific config (K8s patterns, repo conventions) belongs in the project's own `CLAUDE.md` or agent files, not here.

## Sync Workflow

```bash
# Pull latest dotfiles and re-apply config
./claude/refresh.sh

# After editing config locally in ~/.claude/, sync changes back to dotfiles
./claude/sync-to-dotfiles.sh
```

- **`refresh.sh`** — `git pull` + re-run installer. Safe to run repeatedly.
- **`sync-to-dotfiles.sh`** — copies any non-symlinked local changes back to the repo. Only syncs files that exist in dotfiles (won't pull in project-specific config).

Note: `settings.local.json` is **copied** (not symlinked) since it's environment-specific. Use `sync-to-dotfiles.sh` to push local edits back.

## Installation

```bash
# Standalone
./claude/install-claude.sh

# Or via full dotfiles install (called automatically)
./install.sh
```

After install, run `./claude/verify.sh` to check everything is wired up correctly.

**Bootstrap on a new machine**: Run Claude Code once (creates `~/.claude.json`), quit, run the installer, then start Claude Code again.

The installer:
- Detects environment (macOS / Codespaces / Linux) and deploys matching `settings.local.json`
- Symlinks `CLAUDE.md`, `settings.json`, `statusline.sh` into `~/.claude/`
- Symlinks skills, hooks, and agents from this repo
- Merges MCP server config into `~/.claude.json` (without overwriting runtime state)
- Backs up any existing `settings.json` before overwriting
- Preserves `~/.claude.json` (runtime state) and `~/.claude/projects/` (memory)
- Warns if `gh` or `jq` are missing

## Directory Structure

```
claude/
├── install-claude.sh              # Installer (symlinks into ~/.claude/)
├── refresh.sh                     # Pull dotfiles + re-run installer
├── sync-to-dotfiles.sh            # Sync local edits back to dotfiles repo
├── CLAUDE.md                      # Global instructions (repo-agnostic)
├── settings.json                  # Base settings (source of truth)
├── settings.local.macos.json      # macOS overrides
├── settings.local.linux.json      # Linux/EC2 overrides
├── settings.local.codespaces.json # Codespaces overrides
├── statusline.sh                  # Status line script
├── skills/
│   ├── review/SKILL.md            # /review — code review
│   ├── verify/SKILL.md            # /verify — setup health check
│   ├── sync-to-dotfiles/SKILL.md  # /sync-to-dotfiles — local → repo
│   ├── sync-from-dotfiles/SKILL.md # /sync-from-dotfiles — repo → local
│   ├── focus/SKILL.md             # /focus — load workstream context
│   ├── threads/SKILL.md           # /threads — list work threads
│   ├── resume/SKILL.md            # /resume — alias for /focus
│   └── handoff/SKILL.md           # /handoff — end-of-session summary
├── hooks/
│   ├── guard-destructive.sh       # Blocks force push, reset --hard, dangerous rm
│   ├── notify.sh                  # Platform-aware notifications
│   ├── session-journal.sh         # Stop: session journal + thread tracking
│   └── inject-context.sh          # Setup: recent threads orientation
├── verify.sh                      # Validate setup is correct
├── agents/                        # Custom sub-agents (future)
├── README.md                      # This file
└── TIPS.md                        # Workflow tips and feature reference
```

## Adding New Config

- **New skill**: Create `claude/skills/<name>/SKILL.md`, re-run installer
- **New agent**: Create `claude/agents/<name>.md`, re-run installer
- **New MCP server**: Add `jq` merge logic to `install-claude.sh` under the MCP section
- **Environment override**: Edit `settings.local.<env>.json` in dotfiles, re-run installer
- **Project-specific config**: Use `CLAUDE.md`, `.claude/settings.json`, or agent files in the project repo
