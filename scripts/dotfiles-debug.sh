#!/usr/bin/env bash
# dotfiles-debug.sh — portable diagnostics for install troubleshooting
# Run standalone or auto-fired by install.sh trap on failure.

set -euo pipefail

section() {
  echo ""
  echo "━━━ $1 ━━━"
}

check_tool() {
  local name="$1"
  local cmd="${2:-$1}"
  if command -v "$cmd" &>/dev/null; then
    local version
    version=$("$cmd" --version 2>/dev/null | head -1) || version="(installed, version unknown)"
    printf "  ✅ %-14s %s\n" "$name" "$version"
  else
    printf "  ❌ %-14s MISSING\n" "$name"
  fi
}

check_symlink() {
  local link="$1"
  local label="${2:-$1}"
  if [[ -L "$link" ]]; then
    local target
    target=$(readlink "$link")
    if [[ -e "$link" ]]; then
      printf "  ✅ %-40s → %s\n" "$label" "$target"
    else
      printf "  ❌ %-40s → %s (BROKEN)\n" "$label" "$target"
    fi
  elif [[ -e "$link" ]]; then
    printf "  ⚠️  %-40s exists but is not a symlink\n" "$label"
  else
    printf "  ❌ %-40s does not exist\n" "$label"
  fi
}

# ---------------------------------------------------------------------------
section "OS Info"
# ---------------------------------------------------------------------------
echo "  uname: $(uname -a)"
if [[ -f /etc/os-release ]]; then
  echo "  os-release: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
fi
echo "  OSTYPE: ${OSTYPE:-unknown}"

# ---------------------------------------------------------------------------
section "Shell Info"
# ---------------------------------------------------------------------------
echo "  SHELL: ${SHELL:-not set}"
if command -v zsh &>/dev/null; then
  echo "  zsh version: $(zsh --version 2>/dev/null)"
else
  echo "  zsh: NOT INSTALLED"
fi
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo "  oh-my-zsh: installed"
else
  echo "  oh-my-zsh: not found"
fi

# ---------------------------------------------------------------------------
section "Tool Inventory"
# ---------------------------------------------------------------------------
check_tool shellcheck
check_tool jq
check_tool fzf
check_tool ripgrep rg
check_tool bat
check_tool batcat  # Debian/Ubuntu alternative
check_tool eza
check_tool exa     # older alternative
check_tool tmux
check_tool nvim
check_tool gh
check_tool lazygit
check_tool atuin
check_tool kubectl
check_tool brew

# ---------------------------------------------------------------------------
section "Symlink Health"
# ---------------------------------------------------------------------------
check_symlink "$HOME/.zshrc"                         "\$HOME/.zshrc"
check_symlink "$HOME/.p10k.zsh"                      "\$HOME/.p10k.zsh"
check_symlink "$HOME/.config/ghostty/config"         "\$HOME/.config/ghostty/config"
check_symlink "$HOME/.config/tmux/tmux.conf"         "\$HOME/.config/tmux/tmux.conf"
check_symlink "$HOME/.config/tmux/theme.conf"        "\$HOME/.config/tmux/theme.conf"
check_symlink "$HOME/.config/lazygit/config.yml"     "\$HOME/.config/lazygit/config.yml"

# ---------------------------------------------------------------------------
section "Disk & Memory"
# ---------------------------------------------------------------------------
echo "  Disk:"
df -h / 2>/dev/null | tail -1 | awk '{printf "    used: %s / %s (%s)\n", $3, $2, $5}'

if command -v free &>/dev/null; then
  echo "  Memory:"
  free -h 2>/dev/null | awk '/Mem:/{printf "    used: %s / %s\n", $3, $2}'
elif [[ "$(uname)" == "Darwin" ]]; then
  echo "  Memory: $(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f GB total", $1/1073741824}')"
fi

# ---------------------------------------------------------------------------
# Cloud-init logs (Linux only)
# ---------------------------------------------------------------------------
if [[ -f /var/log/cloud-init-output.log ]]; then
  section "Cloud-Init (last 50 lines)"
  tail -50 /var/log/cloud-init-output.log
fi

# ---------------------------------------------------------------------------
# Dotfiles status marker
# ---------------------------------------------------------------------------
if [[ -f "$HOME/.dotfiles-status" ]]; then
  section "Dotfiles Status ($HOME/.dotfiles-status)"
  cat "$HOME/.dotfiles-status"
fi

echo ""
