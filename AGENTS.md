# Agent Instructions

Personal dotfiles repo. Primary: macOS ARM64. Also targets Linux, Codespaces, and devcontainers.

## Git Workflow

- Always create a feature branch from `master`. Never push directly to `master`.
- Branch naming: `feat/`, `fix/`, `chore/`, `docs/`, `ci/` + short kebab-case (e.g., `feat/add-fzf-preview`)
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `ci:`
- Open PRs via `gh pr create`. Squash merge only. Branches auto-delete after merge.
- Run `scripts/ci/lint.sh` before pushing.

## Conventions

- Shell scripts: `set -euo pipefail`. Use `$HOME`, not hardcoded paths.
- Scripts must pass `shellcheck` and `bash -n`.
- All new `.sh` files and hooks must be executable (`chmod +x`).
- Match the style of neighboring files — look before writing.

## Don't Touch

- `.zshrc` aliases and functions (`ga`, `gc`, `gp`, etc.) unless explicitly asked.
- `p10k.zsh` — auto-generated Powerlevel10k config.
- Files inside `/Applications/`, `/System/`, or `/Library/`.

## Key Directories

| Directory | What it manages |
|-----------|----------------|
| `alfred/` | Alfred workflows (macOS only) |
| `claude/` | Claude Code config: CLAUDE.md, settings, hooks, skills, docs |
| `ghostty/` | Ghostty terminal emulator config |
| `git/` | Global git hooks (applied via `core.hooksPath`) |
| `lazygit/` | LazyGit config and theme |
| `nvim/` | Neovim/LazyVim bootstrap notes |
| `plans/` | Implementation plans and agent prompts |
| `scripts/` | Utility scripts (`ask`, CI lint, diagnostics) |
| `themes/` | Color themes (synthwave-charm primary, catppuccin secondary) |
| `tmux/` | tmux config, theme, cheatsheet |
