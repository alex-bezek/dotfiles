# Claude Code Backlog

Claude-specific improvements, ideas, and things to explore. Items migrate to the README's "What's Configured" section once implemented.

Cross-agent work (shared roles, parity, agent audit) lives in [`../BACKLOG.md`](../BACKLOG.md).

## To Do

### Hooks
- [ ] **PostToolUse: auto-format on edit** — Run `gofmt`/`goimports` after file edits so unformatted Go never gets committed
- [ ] **Guard: git checkout/restore** — `guard-destructive.sh` misses `git checkout .` and `git restore .` which discard all unstaged changes
- [ ] **TaskCompleted: test runner template** — Generic quality gate that detects project language (go.mod → `go test`, package.json → `npm test`, etc.) and runs tests when a task completes. Ship as a template in dotfiles that repos can copy and customize.
- [ ] **Hook to read agent.md files** — [Reference](https://github.com/anthropics/claude-code/issues/6235#issuecomment-3218728961)

### MCP Servers
- [ ] **Buildkite** — Check build status, trigger pipelines, read logs. Daily use for CI debugging.
- [ ] **Datadog** — Query dashboards/monitors when debugging perf issues
- [ ] **AWS** — Cloud resource management for EC2 dev workflows
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

### Configuration
- [ ] **claude/rules/ directory** — Organize rules into separate files instead of one big CLAUDE.md. See [docs](https://code.claude.com/docs/en/memory#organize-rules-with-claude%2Frules%2F).
- [ ] **Per-project CLAUDE.md patterns** — Document recommended structure for adding Claude config to team repos
- [ ] **Remove "Update available" from status line** — Filter out brew upgrade nag from Claude status output

## Ideas / Someday

- [ ] **Sentry MCP** — Error tracking, investigate production errors in context
- [ ] **Notion MCP** — Team docs, runbooks, design docs (low priority — migrating away)
- [ ] **PostToolUse: secrets scanner** — Regex grep on written files for API keys, tokens, credentials
- [ ] **Claude Code online** — Set up `claude.ai/code` for repo interaction when away from terminal
- [ ] **Copying large text out of Claude** — Document best practices for extracting large outputs
- [ ] **Screenshots over SSH** — Known limitation. No clear workaround yet.
- [ ] **claude-peers-mcp** — Peer-to-peer MCP server for multi-agent collaboration
- [ ] **Worktree-based workflows** — Test with nix-based repos to see if nix setup causes issues
- [ ] **Content writer subagent** — Blog posts, changelogs, release notes
- [ ] **On-call guide subagent** — Runbook-aware debugging assistant

## Done

- [x] MCP: Linear, Playwright, Slack (built-in), Context7 (plugin)
- [x] LSP plugin (gopls) for Go symbol navigation
- [x] Auto memory + CLAUDE.md with communication/code/Go/git rules
- [x] 8 custom skills: /review, /focus, /note, /projects, /verify, /sync-to-dotfiles, /sync-from-dotfiles, /resurrect
- [x] 3+ hooks: notify, guard-destructive, guard-secrets, inject-context, brain-sync
- [x] Status line: model, branch, changed files, context %, cost
- [x] Auto mode (opt-in, two-stage classifier)
- [x] Voice input (macOS, disabled on Linux/Codespaces)
- [x] Custom spinner verbs
- [x] Skill creator plugin
- [x] TIPS.md with workflow reference
- [x] Concise plans, unresolved questions early, verification in plans (CLAUDE.md)
- [x] Platform-aware notifications
- [x] Guard hook for force push, reset --hard, clean -f, dangerous rm -rf
- [x] Brain system with git-backed sync
- [x] AGENT_TEAMS env var enabled
