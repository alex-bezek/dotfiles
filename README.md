# Dotfiles

Shell environment dotfiles for Linux (GitHub Codespaces, devcontainers, EC2) and macOS. Optimized for Kubernetes infrastructure engineering.

## Quick Start

```bash
git clone https://github.com/alex-bezek/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
exec zsh
```

## What's Installed

### Core (always installed)
- **Oh My Zsh** - Zsh framework
- **Powerlevel10k** - Beautiful zsh theme
- **zsh-autosuggestions** - Fish-like autosuggestions
- **zsh-syntax-highlighting** - Syntax highlighting in terminal

### Linux Tools (when on Linux)
- **Homebrew** - Package manager for Linux (optional but recommended)
- **Modern CLI tools** via Homebrew: exa, bat, fzf, ripgrep, neovim, tmux, thefuck, autojump

### Kubernetes Tools (if kubectl present)
- **krew** - kubectl plugin manager
- **krew plugins**: ctx, ns, neat, tail
- **kubecolor** - Colorized kubectl output

## Use with Devcontainers

Add to your project's `.devcontainer/devcontainer.json`:

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

Or if using GitHub Codespaces dotfiles feature, just set this repo as your dotfiles repository in GitHub settings.

## Use with GitHub Codespaces

1. Go to https://github.com/settings/codespaces
2. Set **Dotfiles repository** to: `alex-bezek/dotfiles`
3. Set **Dotfiles install command** to: `./install.sh`
4. Your next Codespace will automatically use these dotfiles

## Configuration

The `.zshrc` adapts to your environment:

### Editor Selection
- Uses `nvim` in Codespaces/containers (detected via `$CODESPACES` or missing `code` binary)
- Uses VS Code (`code`) on macOS

### Custom Git SSH Key
Place your key at `~/.ssh/github_key` and it will be auto-configured.

### Environment Variables
Default values can be overridden via environment variables:

```bash
export AWS_PROFILE="production"
export NGROK_ENV="staging"
export NGROK_EMAIL="alex@ngrok.com"
```

### Local Overrides
Create `~/.zshrc.local` for machine-specific config:

```bash
# ~/.zshrc.local
export AWS_PROFILE="my-profile"
alias k="kubectl --context=prod"
```

Then add to the end of `.zshrc`:
```bash
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

## Shell Aliases & Functions

### Git
```bash
gs          # git status
gd          # git diff (with bat if available)
gdt         # git diff (with difftastic if available)
gc "msg"    # git add . && git commit -m "msg"
gp          # git push to current branch
ga "msg"    # commit and push in one command
```

### Kubernetes
```bash
k           # kubecolor (colored kubectl)
kctx        # kubectl ctx (switch contexts)
kns         # kubectl ns (switch namespaces)
```

### File Operations
```bash
ls          # exa with colors and icons (if installed)
cat         # bat with syntax highlighting (if installed)
vi          # nvim
f           # thefuck - correct previous command
h           # history search with fzf (if installed)
```

### Custom Functions
```bash
nds staging     # Set NGROK_ENV variable (shown in prompt)
t 2             # tree with depth 2
```

## Powerlevel10k Configuration

After first install, run:
```bash
p10k configure
```

This will guide you through customizing your prompt. The configuration is saved to `~/.p10k.zsh`.

## Troubleshooting

### Fonts not rendering correctly
Install a [Nerd Font](https://www.nerdfonts.com/) (like MesloLGS NF) and set it in your terminal.

### Homebrew on Linux
If you skipped Homebrew during install, you can install it later:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then add to your `.zshrc`:
```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

### kubectl not found
Your devcontainer should install kubectl. If not, install it via your devcontainer features or manually.

### Permission denied when changing shell
Run manually:
```bash
sudo chsh -s $(which zsh) $USER
```

## Updating

```bash
cd ~/.dotfiles
git pull
./install.sh
```

## What About macOS?

Your Mac is already set up! This repo primarily helps replicate your Mac environment in Linux devcontainers, Codespaces, and EC2 instances. The install script works on macOS but is optimized for Linux usage.

## License

MIT
