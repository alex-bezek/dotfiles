# Dotfiles — Agent Guide

## Cross-Platform Setup

These dotfiles target **three environments**:

| Environment | OS | Notes |
|---|---|---|
| Local Mac | macOS (arm64) | Primary dev machine, Homebrew, Ghostty, full toolchain |
| EC2 | Ubuntu Linux (x86_64) | Minimal — no Homebrew, no git-lfs, no GUI tools |
| GitHub Codespaces | Ubuntu Linux (x86_64) | Containerized, `$CODESPACES` is set, limited sudo |

**Every change must work on all three.** The most common breakage pattern is assuming a macOS tool/path exists on Linux.

## Rules

- **No hardcoded absolute paths** in config that gets symlinked or set globally. Use `$HOME` or `$DOTFILES_DIR`. The dotfiles repo lives at different paths per machine.
- **Guard platform-specific code** with `$OSTYPE` / `$OS` / `uname` checks.
- **Don't assume tools are installed.** Wrap in `command -v` checks. Especially: `brew`, `git-lfs`, `bat` (vs `batcat`), `eza` (vs `exa`), `defaults` (macOS-only).
- **`git config --global` is dangerous.** It applies to ALL repos. Settings like `filter.lfs.required=true` or `core.hooksPath=/absolute/mac/path` will break git on boxes missing those tools/paths. Make them conditional.
- **`install.sh` is the entry point.** It detects the OS and branches. Linux installs via apt first, Homebrew is optional and skipped in Codespaces.

## Key Files

- `install.sh` — Main installer, runs on all platforms
- `.zshrc` — Shell config, symlinked to `~/.zshrc`
- `git/config` — Symlinked to `~/.gitconfig` (keep portable, no platform-specific settings here)
- `claude/install-claude.sh` — Claude Code setup, runs at end of install
- `themes/` — Terminal color themes, applied via symlinks
- `scripts/` — Shell utilities sourced by `.zshrc`
