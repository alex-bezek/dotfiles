# Dotfiles Backlog

Repo-wide improvements, experiments, and ideas that are broader than the Claude Code setup.

Use this file for things like:

- shell and CLI workflow improvements
- terminals, prompts, tmux, editors, and other dev UX tools
- cross-environment bootstrap issues
- new local tools, agents, or supporting utilities to evaluate

Claude-specific ideas should stay in [`claude/BACKLOG.md`](./claude/BACKLOG.md).

This file is intentionally a mix of:

- real near-term work
- experiments worth trying
- ideas I want written down so I do not forget them

## High Priority

### Cross-Environment Setup

- [ ] Make the install story more obviously consistent across macOS, Linux, Codespaces, and devcontainers
- [ ] Add a non-Claude verification pass for shell/tooling setup (`zsh`, Ghostty, tmux, Starship, editor bootstrap)
- [ ] Decide which tools are required vs optional so install output and docs can be clearer

### Documentation

- [ ] Add a short "what I actually use every day" section for terminal/editor/tooling outside the Claude docs
- [ ] Make it clearer which configs are mature, which are active experiments, and which are just ideas

## Medium Priority

### Terminal & Session UX

- [ ] Refine Ghostty/tmux/Starship docs so they describe the intended workflow together, not as isolated configs
- [ ] Decide whether tmux session management should stay centered on `sesh` or expand to worktrees/project launch helpers
- [ ] Review terminal font/theme assumptions and document the minimum required setup

### Editor & Dev Tools

- [ ] Decide whether LazyVim bootstrap should stay "starter only" or become a repo-managed editor config
- [ ] Review additional tools worth standardizing across machines: `direnv`, `lnav`, `fx`, difftastic, etc.
- [ ] Decide how much AI tooling beyond Claude should be first-class in this repo versus ad hoc/local

### AI Tooling & Agents

- [ ] Track non-Claude tools to evaluate: Codex, Crush, opencode, Amp, and future agent-oriented CLIs
- [ ] Decide whether there should be a shared pattern for installing/evaluating agent tools across environments
- [ ] Document when a tool is "installed for experimentation" versus "part of the normal workflow"
- [ ] Evaluate Copilot agentic workflows — see https://awesome-copilot.github.com/learning-hub/agentic-workflows/
- [ ] Evaluate AI-native IDEs: agentastic.dev, Kiro


## Low Priority

### Structural Ideas

- [ ] Consider splitting installers by concern if `install.sh` keeps growing (shell, terminal, editor, AI, Claude)
- [ ] Add a changelog or "recent additions" note if remembering new capabilities becomes harder over time
- [ ] Consider a lightweight machine-profile concept for workstation vs container vs VM differences

## Explore / Research

- [ ] New terminal tools and workflows worth trying
- [ ] Editor support beyond LazyVim
- [ ] Additional agent/tool ecosystems that complement Claude without making the repo noisy
- [ ] Better ways to document "ideas vs adopted defaults" without turning the repo into a project-management system

## Done

- [x] Root README rewritten to explain the repo as both automation and living documentation
- [x] Root README now describes environments, normal loops, and the stable/evolving/experimental split
- [x] Added repo-wide backlog separate from `claude/BACKLOG.md`
- [x] Standardized LazyGit as the repo-managed Git TUI with shared theming, shell wrapper, and a starter cheatsheet
