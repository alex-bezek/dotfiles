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

install_powerlevel10k() {
  P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ ! -d "$P10K_DIR" ]]; then
    echo "💎 Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  else
    echo "✅ Powerlevel10k already installed"
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

install_linux_tools_apt() {
  echo "📦 Installing Linux tools via apt..."

  if ! command -v apt-get &> /dev/null; then
    echo "⚠️  apt-get not available, skipping apt installs"
    return
  fi

  sudo apt-get update -qq || true

  # Core tools that are commonly available via apt
  sudo apt-get install -y -qq \
    curl wget git build-essential \
    fzf ripgrep jq tree neovim tmux autojump \
    2>/dev/null || echo "⚠️  Some apt packages failed to install"

  # bat is called 'batcat' on Ubuntu/Debian
  if ! command -v bat &> /dev/null; then
    sudo apt-get install -y -qq bat 2>/dev/null || \
    sudo apt-get install -y -qq batcat 2>/dev/null || true
  fi

  # exa/eza - try eza first (newer), then exa
  if ! command -v exa &> /dev/null && ! command -v eza &> /dev/null; then
    sudo apt-get install -y -qq eza 2>/dev/null || \
    sudo apt-get install -y -qq exa 2>/dev/null || true
  fi

  # thefuck
  if ! command -v thefuck &> /dev/null; then
    sudo apt-get install -y -qq thefuck 2>/dev/null || \
    pip3 install --user thefuck 2>/dev/null || true
  fi
}

install_linux_tools_brew() {
  echo "📦 Attempting Homebrew install for remaining tools..."

  # Install Homebrew for Linux if not present
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
    # Only install what apt couldn't provide
    for tool in exa bat thefuck; do
      if ! command -v "$tool" &> /dev/null; then
        brew install "$tool" 2>/dev/null || echo "⚠️  $tool failed to install via brew"
      fi
    done
  fi
}

install_linux_tools() {
  echo "📦 Installing Linux tools..."

  # Prefer apt for speed and reliability in containers
  install_linux_tools_apt

  # Only try Homebrew if we're missing key tools and not in a minimal container
  if [[ -z "$CODESPACES" ]] && [[ -z "$REMOTE_CONTAINERS" ]]; then
    # Check if we're missing tools that apt couldn't provide
    local missing_tools=0
    for tool in exa bat thefuck; do
      if ! command -v "$tool" &> /dev/null && ! command -v "${tool}cat" &> /dev/null; then
        ((missing_tools++))
      fi
    done

    if [[ $missing_tools -gt 0 ]]; then
      read -t 10 -p "Install Homebrew for additional tools? [y/N] " -n 1 -r || REPLY="n"
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_linux_tools_brew
      fi
    fi
  fi
}

install_macos_tools() {
  echo "📦 Installing macOS tools..."

  if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  echo "📦 Installing CLI tools via Homebrew..."
  brew install exa bat fzf ripgrep jq tree neovim tmux thefuck autojump kubecolor 2>/dev/null || \
    echo "⚠️  Some tools failed to install via brew"
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
      # Install from GitHub releases
      KUBECOLOR_VERSION=$(curl -s https://api.github.com/repos/hidetatz/kubecolor/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
      OS_LOWER="$(uname -s | tr '[:upper:]' '[:lower:]')"
      ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64$/arm64/')"

      curl -sL "https://github.com/hidetatz/kubecolor/releases/download/v${KUBECOLOR_VERSION}/kubecolor_${KUBECOLOR_VERSION}_${OS_LOWER}_${ARCH}.tar.gz" | tar xz -C /tmp
      mkdir -p "$HOME/.local/bin"
      mv /tmp/kubecolor "$HOME/.local/bin/"
      chmod +x "$HOME/.local/bin/kubecolor"

      # Add to PATH if not already there
      if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
      fi
    fi
  else
    echo "✅ kubecolor already installed"
  fi
}

setup_symlinks() {
  echo "🔗 Creating symlinks..."

  # Backup existing .zshrc if it exists and isn't a symlink
  if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    echo "📦 Backing up existing .zshrc to .zshrc.backup"
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
  fi

  ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

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

  # In Codespaces/containers, use sudo chsh which doesn't prompt for password
  if [[ -n "$CODESPACES" ]] || [[ -n "$REMOTE_CONTAINERS" ]] || [[ -f /.dockerenv ]]; then
    sudo chsh -s "$ZSH_PATH" "$(whoami)" || echo "⚠️  Could not set zsh as default"
  else
    # On regular systems, try without sudo first
    chsh -s "$ZSH_PATH" 2>/dev/null || echo "⚠️  Could not set zsh as default (run 'chsh -s $ZSH_PATH' manually)"
  fi
}

main() {
  echo ""
  echo "🎯 Focus: Oh My Zsh + Powerlevel10k + plugins"
  echo ""

  # Core installations (always run)
  install_ohmyzsh
  install_powerlevel10k
  install_zsh_plugins

  # Platform-specific tools
  if [[ "$OS" == "linux" ]]; then
    install_linux_tools
  elif [[ "$OS" == "macos" ]]; then
    install_macos_tools
  fi

  # Kubernetes tools (nice-to-have, may fail gracefully)
  if command -v kubectl &> /dev/null; then
    install_krew
    install_krew_plugins
    install_kubecolor
  else
    echo "⚠️  kubectl not found, skipping krew/kubecolor (install kubectl first if needed)"
  fi

  # Setup dotfiles
  setup_symlinks
  set_zsh_default

  echo ""
  echo "✨ Dotfiles setup complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Restart your terminal or run: exec zsh"
  echo "  2. Run 'p10k configure' to customize Powerlevel10k"
  if [[ "$OS" == "linux" ]] && command -v brew &> /dev/null; then
    echo "  3. Add Homebrew to your path if needed:"
    echo "     echo 'eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"' >> ~/.zshrc"
  fi
  echo ""
}

main "$@"
