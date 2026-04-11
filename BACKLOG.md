# Dotfiles Backlog

Ideas, to-dos, and things to look into. Mix of real near-term work, experiments worth trying, and things I want written down so I don't forget them.

Use [`claude/BACKLOG.md`](./claude/BACKLOG.md) only for Claude-specific capabilities, limitations, and integrations.

## To Do

### Cross-Environment Setup

- [ ] Make the install story more consistent across macOS, Linux, Codespaces, and devcontainers
  - [ ] Identify where the current setup/install flow diverges by environment
  - [ ] Close the highest-friction gaps so a fresh setup follows the same mental model everywhere
  - [ ] Leave a short checklist in docs/install output showing what was done, skipped, or is environment-specific
- [ ] Decide which tools are required vs optional so install output and docs can be clearer

### Documentation

- [ ] Add a short "what I actually use every day" section for terminal/editor/tooling
- [ ] Make it clearer which configs are mature, which are active experiments, and which are just ideas
- [ ] Document theme switching: synthwave-charm is primary, catppuccin-mocha is optional secondary

### Ghostty

- [ ] Switch `auto-update-channel` back to `stable` in `ghostty/config` once Ghostty 1.3.2 stable ships (scrollback bug fix — [#11846](https://github.com/ghostty-org/ghostty/discussions/11846))

### Terminal & Session UX

- [ ] Refine Ghostty/tmux/p10k docs so they describe the intended workflow together, not as isolated configs
- [ ] Decide whether tmux session management should stay centered on `sesh` or expand to worktrees/project launch helpers
- [ ] Improve fzf setup — richer keybindings/previews for files, directories, git history beyond the basic `h` alias
- [ ] Document when to use `git diff`, `gdt` (difftastic), and lazygit for review

### Editor & Dev Tools

- [ ] Decide whether LazyVim bootstrap should stay "starter only" or become a repo-managed editor config
- [ ] Review additional tools worth standardizing: `direnv`, `lnav`, `fx`, etc.

### AI Agents — Cross-Agent Work

> This section tracks agent work that isn't specific to one tool. Claude-only items go in [`claude/BACKLOG.md`](./claude/BACKLOG.md). A broader agent audit (feature parity, shared patterns, per-agent config) is planned as a near-term project.

- [ ] Add an agent-configuration overview: shared baseline vs per-agent differences, which conventions should stay consistent
- [ ] Document which agent CLIs are installed as experiments vs supported defaults (Claude, Codex, Crush, opencode, Amp)
- [ ] Create reusable agent roles/workflows worth porting across tools: test writer, build validator, docs writer, code architect, on-call guide
- [ ] Define a generic task-completion verification flow that can run the right test/lint command per project
- [ ] Define a generic agent-assisted commit flow for descriptive commits, validation, and optional history cleanup
- [ ] Design an agent-assisted Git history cleanup workflow (split unrelated changes, fold formatting commits, rewrite messages for intent)
- [ ] Evaluate Copilot agentic workflows — https://awesome-copilot.github.com/learning-hub/agentic-workflows/
- [ ] Evaluate AI-native IDEs: agentastic.dev, Kiro — only if they'd get config/docs in this repo

### Structural

- [ ] Consider splitting installers by concern if `install.sh` keeps growing (shell, terminal, editor, AI)
- [ ] Consider a lightweight machine-profile concept for workstation vs container vs VM differences

## Ideas / Someday

Things I've looked into or want to remember, but no concrete repo change planned yet.

- [ ] Multi-agent orchestration patterns (west world agent team concept, agent teams env var is already set)
- [ ] Agent-assisted on-call / runbook workflow
- [ ] draw.io CLI + AI for auto-generating architecture diagrams
- [ ] Better ways to document "ideas vs adopted defaults" without turning the repo into a project-management system

## Done

- [x] Root README rewritten to explain the repo as both automation and living documentation
- [x] Root README describes environments, normal loops, and stable/evolving/experimental split
- [x] Added repo-wide backlog separate from `claude/BACKLOG.md`
- [x] Standardized LazyGit as the repo-managed Git TUI with shared theming, shell wrapper, cheatsheet
- [x] Catppuccin theme evaluated and set up as secondary; synthwave-charm chosen as primary
- [x] StarShip prompt evaluated and rejected; staying with Powerlevel10k
- [x] Atuin installed and initialized for shell history sync
- [x] Carapace installed and initialized for multi-shell completions
- [x] fzf installed with history alias
- [x] Difftastic installed with `gdt` alias
- [x] Agent CLIs installed: Codex, Crush, opencode, gh-copilot; Amp manual
