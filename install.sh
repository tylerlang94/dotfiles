#!/bin/bash
set -e

#!/usr/bin/env bash
set -euo pipefail

# Where this script lives = your dotfiles root
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Timestamped backup directory
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up existing configs to $BACKUP_DIR…"

# 1) Neovim
NVIM_SRC="$DOTFILES_DIR/nvim"                      # should contain init.vim or init.lua, plus other lua/plugged dirs
NVIM_DEST="$HOME/.config/nvim"

if [ -e "$NVIM_DEST" ] || [ -L "$NVIM_DEST" ]; then
  mv "$NVIM_DEST" "$BACKUP_DIR/"
  echo "  • moved old ~/.config/nvim → backup"
fi

mkdir -p "$(dirname "$NVIM_DEST")"
ln -s "$NVIM_SRC" "$NVIM_DEST"
echo "  ✓ linked nvim config"

# 2) tmux
TMUX_SRC="$DOTFILES_DIR/tmux/.tmux.conf"           # your tmux.conf in a 'tmux' folder
TMUX_DEST="$HOME/.tmux.conf"

if [ -e "$TMUX_DEST" ] || [ -L "$TMUX_DEST" ]; then
  mv "$TMUX_DEST" "$BACKUP_DIR/"
  echo "  • moved old ~/.tmux.conf → backup"
fi

ln -s "$TMUX_SRC" "$TMUX_DEST"
echo "  ✓ linked tmux.conf"

echo "All done! 🎉"

