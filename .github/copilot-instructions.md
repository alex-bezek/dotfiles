# Copilot Instructions

## Project Context

Personal dotfiles repo managing zsh, Ghostty terminal, tmux, lazygit, nvim, git hooks, themes, and AI agent configs (Claude Code, Copilot, Amp, Codex). Primary platform: macOS ARM64. Also targets Linux, GitHub Codespaces, and devcontainers.

Key files: `.zshrc` (shell config), `install.sh` (cross-platform installer), `ghostty/config`, `tmux/tmux.conf`, `lazygit/config.yml`, `claude/` (Claude Code setup with hooks, skills, settings).

Shell scripts use `set -euo pipefail` and must pass `shellcheck`. Use `$HOME`, not hardcoded paths. All changes go through PRs with CI lint checks.

## Code Review Calibration

This is a personal dotfiles repo. "Non-standard" is not a bug. Do not enforce external conventions or best practices that the owner hasn't adopted.

### Only flag these issues

- Secret exposure (API keys, tokens, passwords in committed files)
- Broken symlinks or incorrect symlink targets
- Shell quoting bugs (unquoted variables in conditionals, word splitting risks)
- Portability issues between macOS and Linux (GNU vs BSD flags, missing tool guards)
- Missing `set -euo pipefail` in new shell scripts
- Commands that would fail destructively without error checking

### Do not flag

- Style preferences on config files (Ghostty, tmux, lazygit, p10k)
- Missing tests — this is a dotfiles repo, not a library
- Missing error handling on commands that already have `|| true` or similar guards
- `.zshrc` aliases or shell functions — these are muscle memory, not code review targets
- `p10k.zsh` content — this is an auto-generated 86KB config file
- Theme color values or spinner verb lists
- Lack of documentation or comments
- Variable naming style

### Default stance: approve

Approve every PR unless you find a critical issue (secret exposure, data loss risk, or a change that would break install.sh on a fresh machine). Style nits, missing docs, and non-standard patterns are never grounds for blocking.

When in doubt, approve and leave a non-blocking comment.

### Review intensity

- PRs that only touch config values (not scripts): 0-2 comments maximum
- PRs that modify shell scripts: focus on correctness and portability
- Keep comments terse. No praise, no "looks good overall", no suggestions to add docs
