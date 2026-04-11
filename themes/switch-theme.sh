#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEMES_DIR="$DOTFILES_DIR/themes"

if [[ "$1" == "--list" || "$1" == "-l" ]]; then
  echo "Available themes:"
  current=$(cat "$THEMES_DIR/current" 2>/dev/null || echo "none")
  for dir in "$THEMES_DIR"/*/; do
    name=$(basename "$dir")
    if [[ "$name" == "$current" ]]; then
      echo "  * $name (active)"
    else
      echo "    $name"
    fi
  done
  exit 0
fi

if [[ -z "$1" ]]; then
  echo "Usage: switch-theme.sh <theme-name>"
  echo "       switch-theme.sh --list"
  exit 1
fi

THEME="$1"
THEME_DIR="$THEMES_DIR/$THEME"

if [[ ! -d "$THEME_DIR" ]]; then
  echo "❌ Theme '$THEME' not found in $THEMES_DIR"
  echo "Available themes:"
  ls -1d "$THEMES_DIR"/*/ 2>/dev/null | xargs -I{} basename {}
  exit 1
fi

if [[ ! -f "$THEME_DIR/theme.conf" ]]; then
  echo "❌ Missing theme.conf in $THEME_DIR"
  exit 1
fi

# Read theme.conf
source <(grep -v '^#' "$THEME_DIR/theme.conf" | grep '=')

echo "🎨 Switching to theme: $THEME"

# 1. Update current theme marker
echo "$THEME" > "$THEMES_DIR/current"

# 2. Update Ghostty config
if [[ -n "$ghostty_theme" ]]; then
  sed -i.bak "s/^theme = .*/theme = $ghostty_theme/" "$DOTFILES_DIR/ghostty/config"
  rm -f "$DOTFILES_DIR/ghostty/config.bak"
  echo "  ✅ Ghostty → $ghostty_theme"
fi

# 3. Update Starship palette
if [[ -n "$starship_palette" ]]; then
  sed -i.bak "s/^palette = .*/palette = \"$starship_palette\"/" "$DOTFILES_DIR/starship/starship.toml"
  rm -f "$DOTFILES_DIR/starship/starship.toml.bak"
  echo "  ✅ Starship → $starship_palette"
fi

# 4. Update tmux theme symlink
if [[ -f "$THEME_DIR/tmux-colors.conf" ]]; then
  mkdir -p "$HOME/.config/tmux"
  ln -sf "$THEME_DIR/tmux-colors.conf" "$HOME/.config/tmux/theme.conf"
  echo "  ✅ tmux → $THEME (reload with: tmux source ~/.config/tmux/tmux.conf)"
fi

# 5. Update Lazygit theme symlinks
if [[ -f "$THEME_DIR/lazygit-theme.yml" ]]; then
  mkdir -p "$HOME/.config/lazygit"
  mkdir -p "$HOME/Library/Application Support/lazygit"
  ln -sf "$THEME_DIR/lazygit-theme.yml" "$HOME/.config/lazygit/theme.yml"
  ln -sf "$THEME_DIR/lazygit-theme.yml" "$HOME/Library/Application Support/lazygit/theme.yml"
  echo "  ✅ Lazygit → $THEME"
fi

echo ""
echo "🔄 To apply:"
echo "   1. Reload shell:  exec zsh"
echo "   2. Reload tmux:   tmux source ~/.config/tmux/tmux.conf"
echo "   3. Restart Ghostty for terminal theme change"
echo "   4. Relaunch lazygit windows to pick up the new theme"
if [[ -n "$nvim_colorscheme" ]]; then
  echo "   5. Nvim colorscheme: $nvim_colorscheme"
fi
