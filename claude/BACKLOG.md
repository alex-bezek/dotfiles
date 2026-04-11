# Claude Code Backlog

Prioritized list of Claude-specific improvements, ideas, and things to explore.

This backlog is intentionally scoped to the Claude setup in [`claude/`](./). Broader dotfiles, terminal, editor, or non-Claude tool ideas should go in the repo-wide [`../BACKLOG.md`](../BACKLOG.md).

Items migrate to the README's "What's Configured" section once implemented.

## High Priority

Things that would immediately improve daily workflow.

### Hooks
- [ ] **PostToolUse: auto-format on edit** — Run `gofmt`/`goimports` after file edits so unformatted Go never gets committed
- [x] **SessionEnd: brain sync push** — Push brain repo on session end (currently only pulls on start)
- [ ] **Guard: git checkout/restore** — `guard-destructive.sh` misses `git checkout .` and `git restore .` which discard all unstaged changes

### MCP Servers
- [ ] **Buildkite** — Check build status, trigger pipelines, read logs. Daily use for CI debugging.
- [ ] **Datadog** — Query dashboards/monitors when debugging perf issues

### Dev Environment
- [ ] **Ensure gh CLI auto-installs** — Available on macOS via brew, but should be in devcontainer/nix setup too

## Medium Priority

Useful but not blocking anything right now.

### MCP Servers
- [ ] **AWS** — Cloud resource management for EC2 dev workflows
- [ ] **Sentry** — Error tracking, investigate production errors in context
- [ ] **GitHub MCP** — Evaluate if direct tool access adds value over `gh` CLI via Bash
- [ ] **ngrok API/Docs** — Internal tooling. Wait for official MCP support (mintlify?)

### Subagents
- [ ] **Test writer** — Generate table-driven Go tests following repo patterns
- [ ] **Build validator** — Run build + lint + test after implementation, report results
- [ ] **Docs writer** — Generate/update documentation for completed features
- [ ] **Code architect** — Design review before implementation, suggest patterns

### Plugins
- [ ] **commit-commands** — Git commit workflows including push and PR creation. Evaluate overlap with existing workflow.
- [ ] **pr-review-toolkit** — Specialized agents for PR review. Evaluate overlap with `/review` skill.
- [ ] **context-mode** (`mksglu/context-mode`) — Context management. Evaluate if useful with 1M context.

### Hooks & Automation
- [ ] **PostToolUse: secrets scanner** — Regex grep on written files for API keys, tokens, credentials
- [ ] **Git commit hooks via agent harness** — Use git to save changes with descriptive notes, commit hooks to validate
- [ ] **TaskCompleted: test runner template** — Generic quality gate that detects project language (go.mod → `go test`, package.json → `npm test`, etc.) and runs tests when a task completes. Ship as a template in dotfiles that repos can copy and customize. Inspired by ngrok-operator's per-package verify-fix.sh hook.
- [ ] **Hook to read agent.md files** — [Reference](https://github.com/anthropics/claude-code/issues/6235#issuecomment-3218728961)

### Configuration
- [ ] **claude/rules/ directory** — Organize rules into separate files instead of one big CLAUDE.md. See [docs](https://code.claude.com/docs/en/memory#organize-rules-with-claude%2Frules%2F).
- [ ] **Per-project CLAUDE.md patterns** — Document recommended structure for adding Claude config to team repos
- [ ] **Claude Code online** — Set up `claude.ai/code` for repo interaction when away from terminal
- [ ] **Remove "Update available" from status line** — Filter out brew upgrade nag from Claude status output
- [ ] **Copying large text out of Claude** — Document best practices for extracting large outputs (files, logs) from Claude sessions

## Low Priority

Nice to have, exploratory, or waiting on external factors.

### MCP Servers
- [ ] **Notion** — Team docs, runbooks, design docs. Low priority since migrating away from it.
- [ ] **Figma** — Design specs. Only useful if doing frontend work.
- [ ] **PostHog** — Product analytics data

### Subagents (Speculative)
- [ ] **Content writer** — Blog posts, changelogs, release notes
- [ ] **On-call guide** — Runbook-aware debugging assistant
- [ ] **Agent teams** — Find a large multi-file task to test team delegation
- [ ] **"West world" agent team** — Multi-agent team pattern with specialized personas for complex tasks

### MCP Servers (Speculative)
- [ ] **claude-peers-mcp** — Peer-to-peer MCP server for multi-agent collaboration

### Environment & Platform
- [ ] **Voice input across environments** — Works on macOS. VM/Codespaces need investigation (possibly desktop app or web app).
- [ ] **Screenshots over SSH** — Known limitation. No clear workaround yet.
- [ ] **Claude Desktop "Cowork"** — Investigate what this mode is useful for

### Workflow
- [ ] **Propose shared team config** — Once patterns stabilize, push Claude config into shared repos
- [ ] **Worktree-based workflows** — Test with nix-based repos to see if nix setup causes issues in worktrees

## Explore / Research

Things to look into that aren't concrete tasks yet.

- [ ] **n8n** — Workflow automation platform. Evaluate use cases with Claude.
- [ ] **ralph** (`snarktank/ralph`) — Already have ralph-loop plugin. Evaluate if the standalone tool adds value.
- [ ] **LightRAG** (`hkuds/lightrag`) — Vector DB for large file sets (500+ files). Evaluate for large monorepos.
- [ ] **nanobot vs openclaw** — Compare agent frameworks
- [ ] **CLI Anything** (`clianything.cc`) — CLI tools ecosystem
- [ ] **draw.io CLI + Claude** — Auto-generate architecture diagrams from code
- [ ] **AI newsletters/feeds** — Find good sources to stay current on tools and techniques
- [ ] **Keybindings customization** — Not yet customized. Consider setting up shortcuts for common workflows.
- [ ] **Local Ollama models with Claude** — Use local models as a fallback or for cheaper tasks
- [ ] **OpenRouter** — Free hosted models as an alternative backend

## Done

Completed items moved here for reference. See README.md for full details of what's configured.

- [x] MCP: Linear, Playwright, Slack (built-in), Context7 (plugin)
- [x] LSP plugin (gopls) for Go symbol navigation
- [x] Auto memory + CLAUDE.md with communication/code/Go/git rules
- [x] 8 custom skills: /review, /focus, /note, /projects, /verify, /sync-to-dotfiles, /sync-from-dotfiles, /resurrect
- [x] 3 hooks: notify, guard-destructive, inject-context + brain-sync
- [x] Status line: model, branch, changed files, context %, cost
- [x] Auto mode (opt-in, two-stage classifier)
- [x] Voice input (macOS, disabled on Linux/Codespaces)
- [x] Custom spinner verbs
- [x] Skill creator plugin
- [x] TIPS.md with workflow reference (/context, Shift+Tab, /compact, /rewind, worktrees, etc.)
- [x] Concise plans, unresolved questions early, verification in plans (CLAUDE.md)
- [x] Platform-aware notifications (macOS osascript, Linux notify-send, fallback bell)
- [x] Guard hook for force push, reset --hard, clean -f, dangerous rm -rf
- [x] Brain system with git-backed sync (pull on start, push on /note)
