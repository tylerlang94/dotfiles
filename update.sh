#!/usr/bin/env bash

set -euo pipefail

REPO_URL="git@github.com:tylerlang94/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

if [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo "Cloning dotfiles into $DOTFILES_DIR…"
  git clone "$REPO_URL" "$DOTFILES_DIR"
else
  echo "Updating existing dotfiles in $DOTFILES_DIR…"
  git -C "$DOTFILES_DIR" pull --ff-only
fi

# 3) Run your existing install script
if [ -x "$DOTFILES_DIR/install.sh" ]; then
  echo "Running install.sh…"
  bash "$DOTFILES_DIR/install.sh"
else
  echo "Error: $DOTFILES_DIR/install.sh not found or not executable."
  exit 1
fi

echo "Done!"

