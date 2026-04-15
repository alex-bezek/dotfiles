#!/usr/bin/env bash
#
# macOS defaults — preferences that would be lost on a new Mac.
# Run: bash macos/defaults.sh
# Most changes require logout or restart to take effect.

set -e

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "⚠️  Not macOS, skipping defaults"
  exit 0
fi

echo "🍎 Applying macOS defaults..."

# --- Appearance ---
# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
# Purple accent color
defaults write NSGlobalDomain AppleAccentColor -int 4
# Blue highlight color
defaults write NSGlobalDomain AppleHighlightColor -string "0.698039 0.843137 1.000000 Blue"

# --- Keyboard ---
# Fast key repeat (2 = fastest practical; default is 6)
defaults write NSGlobalDomain KeyRepeat -int 2
# Short delay before repeat (15 = fast; default is 25)
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable press-and-hold character picker (enables key repeat in all apps)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Use F1, F2, etc. as standard function keys
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
# Tab moves focus between all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

# --- Trackpad/Mouse ---
# Fast tracking speed
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3
defaults write NSGlobalDomain com.apple.mouse.scaling -float 3

# --- Dock ---
# Auto-hide dock
defaults write com.apple.dock autohide -bool true
# Icon size 48px
defaults write com.apple.dock tilesize -int 48
# Magnification size 128px
defaults write com.apple.dock largesize -int 128

# Hot corners:
#  Top-left     → Mission Control (2)
#  Top-right    → Start Screen Saver (5)
#  Bottom-right → Quick Note (14)
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 5
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

# --- Finder ---
# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Scroll bar click jumps to the clicked spot
defaults write NSGlobalDomain AppleScrollerPagingBehavior -int 1

# --- Menu bar clock ---
# Show AM/PM
defaults write com.apple.menuextra.clock ShowAMPM -bool true
# Show day of week
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
# Hide date
defaults write com.apple.menuextra.clock ShowDate -int 0

# --- Screenshots ---
# Default to clipboard (can be changed in Screenshot.app)
# defaults write com.apple.screencapture location -string "$HOME/Desktop"

# --- Restart affected apps ---
echo "  Restarting Dock..."
killall Dock 2>/dev/null || true

echo "✅ macOS defaults applied"
echo "  Some changes require logout/restart to take effect (keyboard, trackpad)"
