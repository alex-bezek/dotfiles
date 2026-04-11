# Dotfiles

Portable development environment and workflow automation for macOS, Linux, Codespaces, devcontainers, and remote hosts.

This repo is doing two jobs on purpose:

1. Automating setup across the environments I actually work in
2. Documenting the tools, workflows, and experiments I keep adding so I remember to use them

It is not "finished." Some parts are stable and part of my normal loop; other parts are exploratory, backlog-driven, or still being shaped.

## What This Repo Is

The current stack is centered around:

- Shell and CLI setup via `.zshrc` and `install.sh`
- Terminal UX via Ghostty, tmux, and Powerlevel10k
- Git review via LazyGit
- Editor/bootstrap via LazyVim
- Kubernetes/infra ergonomics
- Shared agent/tooling planning in this root README and [`BACKLOG.md`](./BACKLOG.md)
- Claude Code setup, skills, hooks, and provider-specific workflow docs in [`claude/`](./claude)

If you only skim one thing after this file, read [`claude/README.md`](./claude/README.md).

## Environments

This repo is meant to travel across a few different environments with different levels of setup:

| Environment | Role |
|------------|------|
| macOS laptop/workstation | Primary daily environment |
| GitHub Codespaces | Fast remote dev environment |
| Devcontainers | Per-project reproducible setup |
| Linux VMs / EC2 | Utility and infra work |

The goal is not bit-for-bit sameness. The goal is a familiar working model everywhere:

- `zsh` shell with the same aliases/functions
- Similar terminal/editor ergonomics
- Kubernetes and cloud tooling available when relevant
- Claude Code configured the same way, with environment-specific overrides where needed

## Current State

### Stable / In Normal Use

- `.zshrc` shell environment and aliases
- Ghostty config
- tmux config
- Powerlevel10k prompt
- LazyGit config and cheatsheet
- LazyVim bootstrap
- Claude Code setup, hooks, skills, and session docs
- Linux/macOS install automation

### Active But Still Evolving

- Cross-environment bootstrap quality
- AI tooling, shared agent configuration, and agent installation
- Claude workflow automation
- Brain/project-memory workflow
- Verification and sync ergonomics

### Explicitly Experimental

- New MCP servers
- Additional hooks and subagents
- Shared/team patterns
- Workflow ideas tracked in [`BACKLOG.md`](./BACKLOG.md) and [`claude/BACKLOG.md`](./claude/BACKLOG.md)

## Normal Development Loops

These are the main loops this repo appears to support and document.

### 1. Bootstrap a machine or container

```bash
git clone https://github.com/alex-bezek/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
exec zsh
```

That installs or wires up the base shell/tooling stack, then applies Claude config from [`claude/`](./claude).

### 2. Daily development

The intended daily environment looks roughly like:

- Ghostty + tmux as the terminal/session layer
- LazyGit for Git review, staging, history, and branch operations
- Powerlevel10k for the active `zsh` prompt
- `nvim` as the default editor
- Kubernetes helpers available when `kubectl` is present
- Claude Code available with custom hooks, skills, and notes/memory workflow

The shell config makes the infra/Kubernetes/Go bias fairly obvious:

- `EDITOR=nvim`
- `KUBE_EDITOR=code --wait` on local macOS, `nvim` elsewhere
- `kubectl`/`kubecolor` helpers
- AWS/ngrok-specific environment defaults

### 3. Evolve the setup itself

There is a deliberate loop for changing the toolchain over time:

- change files in this repo
- re-run `./install.sh` or `./claude/refresh.sh`
- use [`claude/verify.sh`](./claude/verify.sh) to confirm the Claude setup still matches expectations
- keep shared agent/tooling ideas in [`BACKLOG.md`](./BACKLOG.md) and Claude-only items in [`claude/BACKLOG.md`](./claude/BACKLOG.md)

That is intentional: this repo is both automation and a running record of improvements still worth making.

## Repository Map

| Path | Purpose |
|------|---------|
| [install.sh](./install.sh) | Main cross-environment installer |
| [BACKLOG.md](./BACKLOG.md) | Repo-wide improvements plus shared agent-configuration and parity work |
| [.zshrc](./.zshrc) | Shared shell environment |
| [ghostty/config](./ghostty/config) | Terminal configuration |
| [tmux/tmux.conf](./tmux/tmux.conf) | Session management and terminal multiplexing |
| [tmux/CHEATSHEET.md](./tmux/CHEATSHEET.md) | Small workflow-oriented tmux reference |
| [p10k.zsh](./p10k.zsh) | Active Powerlevel10k prompt configuration for `zsh` |
| [lazygit/config.yml](./lazygit/config.yml) | Shared LazyGit defaults for terminal Git review |
| [lazygit/CHEATSHEET.md](./lazygit/CHEATSHEET.md) | Small LazyGit reference for local and remote use |
| [nvim/CHEATSHEET.md](./nvim/CHEATSHEET.md) | Neovim/LazyVim beginner cheatsheet and personal notes |
| [claude/README.md](./claude/README.md) | Claude Code setup and workflows |
| [claude/TIPS.md](./claude/TIPS.md) | Habit-building reference for Claude features |
| [claude/BACKLOG.md](./claude/BACKLOG.md) | Claude-specific planned, experimental, and unfinished work |

## Installation Notes

### Devcontainers

Example `.devcontainer/devcontainer.json`:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {
      "installZsh": true
    }
  },
  "postCreateCommand": "git clone https://github.com/alex-bezek/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh"
}
```

### GitHub Codespaces

1. Go to `https://github.com/settings/codespaces`
2. Set the dotfiles repository to `alex-bezek/dotfiles`
3. Set the install command to `./install.sh`

## Local Overrides

Use untracked local files for machine-specific tweaks:

- `~/.zshrc.local`
- `~/.claude/settings.local.json`

Example:

```bash
# ~/.zshrc.local
export AWS_PROFILE="my-profile"
alias k="kubectl --context=prod"
```

## Things Still To Do

This project will keep growing. A few categories are intentionally incomplete:

- Better parity across macOS, Linux, Codespaces, and devcontainers
- More verification around non-Claude shell/tooling setup
- More explicit classification of what is "stable" vs "experimental"
- More automation around AI tool installation, shared agent parity, and workflow validation
- Repo-wide and shared agent-configuration ideas live in [`BACKLOG.md`](./BACKLOG.md).
- Claude-specific improvements live in [`claude/BACKLOG.md`](./claude/BACKLOG.md).

## Git Review Recommendation

For the workflow you described, `lazygit` is the right primary tool.

- It works the same on macOS, Linux, Codespaces, and SSH/EC2 boxes
- It gives you a real TUI for diffs, staging, history, rebases, and branch flow
- It pairs cleanly with `tmux`, which is the practical way to manage several machines or repos at once

What it does not give you is a true single unified multi-repo pane across multiple remote hosts. For that, Mac GUI apps can help locally, but they break the moment the source of truth lives inside a remote shell. For this repo, the stronger default is consistency everywhere rather than a richer GUI on only one machine.

## Updating

```bash
cd ~/.dotfiles
git pull
./install.sh
```

## License

MIT
