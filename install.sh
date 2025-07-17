#!/usr/bin/env bash
set -euov pipefail

# 1) Make sure HOME is sane
: "${HOME:?HOME must be set and non-empty}"

# 2) Figure out where your dotfiles repo lives
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 3) Build all of your absolute paths
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
echo "DEBUG: BACKUP_DIR is -> '$BACKUP_DIR'"

NVIM_SRC="$DOTFILES_DIR/nvim"
NVIM_DEST="$HOME/.config/nvim"
TMUX_SRC="$DOTFILES_DIR/tmux"
TMUX_DEST="$HOME/.tmux.conf"

echo "DOTFILES_DIR: $DOTFILES_DIR"
echo "NVIM_SRC:     $NVIM_SRC"
echo "NVIM_DEST:    $NVIM_DEST"
echo "TMUX_SRC:     $TMUX_SRC"
echo "TMUX_DEST:    $TMUX_DEST"

# 4) Quick sanity‑check of your sources
ls -la "$NVIM_SRC"      || { echo "ERROR: NVIM_SRC not found"; exit 1; }
ls -la "$(dirname "$TMUX_SRC")" || { echo "ERROR: TMUX_SRC not found"; exit 1; }
echo "$HOME"
# 5) Prepare backup        
mkdir -p "$BACKUP_DIR"
echo "Backing up old configs into $BACKUP_DIR…"

# 6) NVIM
if [ -e "$NVIM_DEST" ] || [ -L "$NVIM_DEST" ]; then
  mv "$NVIM_DEST" "$BACKUP_DIR/"
  echo "  • moved old ~/.config/nvim → backup"
fi
mkdir -p "$(dirname "$NVIM_DEST")"
ln -sfn "$NVIM_SRC" "$NVIM_DEST"
echo "  ✓ linked nvim config → $NVIM_DEST"

# 7) TMUX
if [ -e "$TMUX_DEST" ] || [ -L "$TMUX_DEST" ]; then
  mv "$TMUX_DEST" "$BACKUP_DIR/"
  echo "  • moved old ~/.tmux.conf → backup"
fi
ln -sfn "$TMUX_SRC" "$TMUX_DEST"
echo "  ✓ linked tmux.conf → $TMUX_DEST"

echo "All done! 🎉"

