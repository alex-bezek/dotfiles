#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Setting up dotfiles..."
echo "Platform: $(uname -s)"

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "linux"
  else
    echo "unknown"
  fi
}

OS=$(detect_os)

install_ohmyzsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "💎 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "✅ Oh My Zsh already installed"
  fi
}

install_zsh_plugins() {
  echo "💎 Installing Zsh plugins..."

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  else
    echo "✅ zsh-autosuggestions already installed"
  fi

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  else
    echo "✅ zsh-syntax-highlighting already installed"
  fi
}

install_lazyvim() {
  if [[ ! -d "$HOME/.config/nvim" ]]; then
    echo "📝 Cloning LazyVim starter..."
    mkdir -p "$HOME/.config"
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    # Remove git history so you can push to your own repo
    rm -rf "$HOME/.config/nvim/.git"
    echo "✅ LazyVim starter cloned to ~/.config/nvim"
    echo "   Run 'nvim' to bootstrap plugins on first launch"
    echo "   Then: cd ~/.config/nvim && git init && git remote add origin <your-fork>"
  else
    echo "✅ LazyVim (~/.config/nvim) already present"
  fi
}

install_linux_tools_apt() {
  echo "📦 Installing Linux tools via apt..."

  if ! command -v apt-get &> /dev/null; then
    echo "⚠️  apt-get not available, skipping apt installs"
    return
  fi

  sudo apt-get update -qq || true

  sudo apt-get install -y -qq \
    zsh curl wget git gh build-essential \
    fzf ripgrep jq tree neovim tmux autojump \
    2>/dev/null || echo "⚠️  Some apt packages failed to install"

  # bat is called 'batcat' on Ubuntu/Debian
  if ! command -v bat &> /dev/null; then
    sudo apt-get install -y -qq bat 2>/dev/null || \
    sudo apt-get install -y -qq batcat 2>/dev/null || true
  fi

  # exa/eza
  if ! command -v exa &> /dev/null && ! command -v eza &> /dev/null; then
    sudo apt-get install -y -qq eza 2>/dev/null || \
    sudo apt-get install -y -qq exa 2>/dev/null || true
  fi

  # Node.js LTS (needed for npm-based agents)
  if ! command -v npx &> /dev/null; then
    echo "📦 Installing Node.js LTS..."
    (curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && \
      sudo apt-get install -y -qq nodejs) || echo "⚠️  Node.js install failed, continuing"
  fi
}

install_linux_tools_brew() {
  echo "📦 Attempting Homebrew install for remaining tools..."

  if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew for Linux..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      echo "⚠️  Homebrew install failed, continuing without it"
      return
    }

    if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  fi

  if command -v brew &> /dev/null; then
    echo "📦 Installing CLI tools via Homebrew..."
    for tool in exa bat atuin lazygit sesh glow gum; do
      if ! command -v "$tool" &> /dev/null; then
        brew install "$tool" 2>/dev/null || echo "⚠️  $tool failed to install via brew"
      fi
    done
  fi
}

install_linux_tools() {
  echo "📦 Installing Linux tools..."

  install_linux_tools_apt

  if [[ -z "$CODESPACES" ]] && [[ -z "$REMOTE_CONTAINERS" ]]; then
    local missing_tools=0
    for tool in atuin lazygit; do
      if ! command -v "$tool" &> /dev/null; then
        missing_tools=$((missing_tools + 1))
      fi
    done

    if [[ $missing_tools -gt 0 ]]; then
      read -t 10 -p "Install Homebrew for additional tools (atuin, lazygit)? [y/N] " -n 1 -r || REPLY="n"
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_linux_tools_brew
      fi
    fi
  fi
}

setup_macos_keyboard() {
  echo "⌨️  Remapping Caps Lock → Control..."

  # Remap Caps Lock (0x700000039) to Left Control (0x7000000E0) for the internal keyboard
  # This mirrors: System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys
  defaults -currentHost write -g com.apple.keyboard.modifiermapping.0-0-0 -array \
    '<dict>
      <key>HIDKeyboardModifierMappingDst</key>
      <integer>30064771299</integer>
      <key>HIDKeyboardModifierMappingSrc</key>
      <integer>30064771129</integer>
    </dict>'

  echo "  ✅ Caps Lock → Control (takes effect after logout/login)"
}

install_macos_tools() {
  echo "📦 Installing macOS tools..."

  if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  echo "📦 Installing CLI tools via Homebrew..."
  brew install \
    eza bat fzf ripgrep jq tree neovim tmux autojump kubecolor node glow gum \
    atuin lazygit sesh \
    2>/dev/null || echo "⚠️  Some tools failed to install via brew"

  # Carapace completions
  brew install carapace 2>/dev/null || echo "⚠️  carapace install skipped"

  # Nerd Font for Ghostty / terminal icons
  echo "📦 Installing JetBrains Mono Nerd Font..."
  brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || \
    echo "⚠️  font-jetbrains-mono-nerd-font install skipped"

  install_agents
}

install_agents() {
  echo "🤖 Installing AI agents..."

  # GitHub Copilot CLI extension
  if command -v gh &> /dev/null; then
    gh extension install github/gh-copilot 2>/dev/null || \
      echo "✅ gh copilot already installed or skipped"
  fi

  # Charmbracelet Crush
  brew install charmbracelet/tap/crush 2>/dev/null || \
    echo "⚠️  crush install skipped"

  # npm-based agents
  if command -v npm &> /dev/null; then
    npm install -g @openai/codex 2>/dev/null || echo "⚠️  codex install skipped"
  fi

  # opencode (check https://opencode.ai for latest install method)
  brew install opencode-ai/tap/opencode 2>/dev/null || \
    echo "⚠️  opencode install skipped (check https://opencode.ai for install instructions)"

  # TODO: Amp (Sourcegraph) — check https://ampai.dev for current install method
  echo "ℹ️  Amp: install manually from https://ampai.dev"
}

install_krew() {
  if [[ ! -d "${KREW_ROOT:-$HOME/.krew}" ]]; then
    echo "☸️  Installing krew..."
    (
      set -x; cd "$(mktemp -d)" &&
      OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
      ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
      KREW="krew-${OS}_${ARCH}" &&
      curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
      tar zxvf "${KREW}.tar.gz" &&
      ./"${KREW}" install krew
    )
  else
    echo "✅ krew already installed"
  fi
}

install_krew_plugins() {
  if [[ -d "${KREW_ROOT:-$HOME/.krew}" ]]; then
    echo "☸️  Installing krew plugins..."
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

    kubectl krew install ctx 2>/dev/null || echo "⚠️  ctx plugin install skipped"
    kubectl krew install ns 2>/dev/null || echo "⚠️  ns plugin install skipped"
    kubectl krew install neat 2>/dev/null || echo "⚠️  neat plugin install skipped"
    kubectl krew install tail 2>/dev/null || echo "⚠️  tail plugin install skipped"
  else
    echo "⚠️  Skipping krew plugins (krew not installed)"
  fi
}

install_kubecolor() {
  if ! command -v kubecolor &> /dev/null; then
    echo "☸️  Installing kubecolor..."
    if command -v brew &> /dev/null; then
      brew install kubecolor
    else
      KUBECOLOR_VERSION=$(curl -s https://api.github.com/repos/hidetatz/kubecolor/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
      OS_LOWER="$(uname -s | tr '[:upper:]' '[:lower:]')"
      ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64$/arm64/')"

      curl -sL "https://github.com/hidetatz/kubecolor/releases/download/v${KUBECOLOR_VERSION}/kubecolor_${KUBECOLOR_VERSION}_${OS_LOWER}_${ARCH}.tar.gz" | tar xz -C /tmp
      mkdir -p "$HOME/.local/bin"
      mv /tmp/kubecolor "$HOME/.local/bin/"
      chmod +x "$HOME/.local/bin/kubecolor"

      if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
      fi
    fi
  else
    echo "✅ kubecolor already installed"
  fi
}

setup_git_hooks() {
  echo "Setting up global git hooks..."
  HOOKS_DIR="$DOTFILES_DIR/git/hooks"

  if [[ -d "$HOOKS_DIR" ]]; then
    git config --global core.hooksPath "$HOOKS_DIR"
    echo "  core.hooksPath -> $HOOKS_DIR"
  fi
}

setup_symlinks() {
  echo "🔗 Creating symlinks..."

  # .zshrc
  if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    echo "📦 Backing up existing .zshrc to .zshrc.backup"
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
  fi
  ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

  # Ghostty
  mkdir -p "$HOME/.config/ghostty"
  ln -sf "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

  # tmux
  mkdir -p "$HOME/.config/tmux"
  ln -sf "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

  # tmux theme (from active theme)
  if [[ -f "$DOTFILES_DIR/themes/current" ]]; then
    local theme
    theme="$(cat "$DOTFILES_DIR/themes/current")"
    if [[ -f "$DOTFILES_DIR/themes/$theme/tmux-colors.conf" ]]; then
      ln -sf "$DOTFILES_DIR/themes/$theme/tmux-colors.conf" "$HOME/.config/tmux/theme.conf"
    fi
  fi

  # Powerlevel10k config
  ln -sf "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"

  # Lazygit
  mkdir -p "$HOME/.config/lazygit"
  ln -sf "$DOTFILES_DIR/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

  # Lazygit on macOS uses ~/Library/Application Support/lazygit by default
  if [[ "$OS" == "macos" ]]; then
    mkdir -p "$HOME/Library/Application Support/lazygit"
    ln -sf "$DOTFILES_DIR/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
  fi

  if [[ -f "$DOTFILES_DIR/themes/current" ]]; then
    local theme
    theme="$(cat "$DOTFILES_DIR/themes/current")"
    if [[ -f "$DOTFILES_DIR/themes/$theme/lazygit-theme.yml" ]]; then
      ln -sf "$DOTFILES_DIR/themes/$theme/lazygit-theme.yml" "$HOME/.config/lazygit/theme.yml"
      if [[ "$OS" == "macos" ]]; then
        ln -sf "$DOTFILES_DIR/themes/$theme/lazygit-theme.yml" "$HOME/Library/Application Support/lazygit/theme.yml"
      fi
    fi
  fi

  # Alfred workflow (cp, not symlink — Alfred ignores symlinked plists)
  if [[ "$OS" == "macos" ]]; then
    # Detect Alfred's sync folder, fall back to default location
    local alfred_sync
    alfred_sync=$(defaults read com.runningwithcrayons.Alfred-Preferences5 syncfolder 2>/dev/null \
      || defaults read com.runningwithcrayons.Alfred-Preferences syncfolder 2>/dev/null \
      || echo "")
    # Expand ~ in the path
    alfred_sync="${alfred_sync/#\~/$HOME}"

    local alfred_prefs=""
    if [[ -n "$alfred_sync" && -d "$alfred_sync/Alfred.alfredpreferences" ]]; then
      alfred_prefs="$alfred_sync/Alfred.alfredpreferences"
    elif [[ -d "$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences" ]]; then
      alfred_prefs="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences"
    fi

    if [[ -n "$alfred_prefs" ]]; then
      local alfred_wf_dir="$alfred_prefs/workflows/user.workflow.ask-llm"
      mkdir -p "$alfred_wf_dir"
      cp -f "$DOTFILES_DIR/alfred/ask.alfredworkflow/info.plist" "$alfred_wf_dir/info.plist"
      echo "  Alfred Ask LLM workflow → $alfred_wf_dir"
    fi
  fi

  # scripts dir
  chmod +x "$DOTFILES_DIR/scripts/"* 2>/dev/null || true

  echo "✅ Symlinks created"
}

set_zsh_default() {
  if [[ "$SHELL" == *"zsh"* ]]; then
    echo "✅ Zsh already default shell"
    return
  fi

  if ! command -v zsh &> /dev/null; then
    echo "⚠️  zsh not found, skipping default shell change"
    return
  fi

  echo "🐚 Setting zsh as default shell..."
  ZSH_PATH="$(which zsh)"

  if [[ -n "$CODESPACES" ]] || [[ -n "$REMOTE_CONTAINERS" ]] || [[ -f /.dockerenv ]] || [[ ! -t 0 ]]; then
    sudo chsh -s "$ZSH_PATH" "$(whoami)" || echo "⚠️  Could not set zsh as default"
  else
    chsh -s "$ZSH_PATH" 2>/dev/null || echo "⚠️  Could not set zsh as default (run 'chsh -s $ZSH_PATH' manually)"
  fi
}

main() {
  echo ""
  echo "🎯 Stack: Ghostty + tmux + Powerlevel10k + LazyVim + AI agents"
  echo ""

  # Platform-specific tools (install before oh-my-zsh so zsh is available on Linux)
  if [[ "$OS" == "linux" ]]; then
    install_linux_tools
  elif [[ "$OS" == "macos" ]]; then
    install_macos_tools
    setup_macos_keyboard
  fi

  # Core shell
  install_ohmyzsh
  install_zsh_plugins

  # LazyVim
  install_lazyvim

  # Kubernetes tools (nice-to-have, may fail gracefully)
  if command -v kubectl &> /dev/null; then
    install_krew
    install_krew_plugins
    install_kubecolor
  else
    echo "⚠️  kubectl not found, skipping krew/kubecolor (install kubectl first if needed)"
  fi

  # Global git hooks
  setup_git_hooks

  # Symlinks for all configs
  setup_symlinks
  set_zsh_default

  # Claude Code configuration
  if [[ -f "$DOTFILES_DIR/claude/install-claude.sh" ]]; then
    echo ""
    echo "🤖 Setting up Claude Code..."
    bash "$DOTFILES_DIR/claude/install-claude.sh"
  fi

  echo ""
  echo "✨ Dotfiles setup complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Restart terminal (or: exec zsh)"
  echo "  2. Open Ghostty — theme: $(cat "$DOTFILES_DIR/themes/current" 2>/dev/null || echo 'default')"
  echo "  3. Run 'nvim' to bootstrap LazyVim plugins (first launch takes ~1 min)"
  echo "  4. In tmux: prefix+T to open sesh session picker"
  echo "  5. Run 'lg' inside any repo for the Lazygit UI"
  echo "  6. Install JetBrains Mono Nerd Font in Ghostty if icons look broken"
  if [[ "$OS" == "linux" ]] && command -v brew &> /dev/null; then
    echo "  7. Add Homebrew to your path if needed:"
    echo "     echo 'eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"' >> ~/.zshrc"
  fi
  echo ""
}

main "$@"
