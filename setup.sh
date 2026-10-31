#!/usr/bin/env bash
# macOS dotfiles bootstrap: Homebrew, core packages, Docker, Nerd Font, then stow.
set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
    echo "[ERROR] This setup script is macOS-only. Old Linux setup lives in archive/." >&2
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
    echo "[INFO] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -d "/opt/homebrew/bin" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -d "/usr/local/bin" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "[INFO] Updating Homebrew..."
    brew update
fi

# --- Packages ---
# fzf and zoxide are required by .zshrc; lazygit is used from nvim and the shell.
brew_packages=("luarocks" "git" "stow" "tmux" "node" "ripgrep" "gopls" "fzf" "zoxide" "lazygit")
for pkg in "${brew_packages[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        echo "[INFO] $pkg is already installed."
    else
        echo "[INFO] Installing $pkg..."
        brew install "$pkg"
    fi
done

# --- Casks ---
# Alacritty is not installed here: its Homebrew cask was disabled (fails Gatekeeper, 2026-09-01).
# Install it manually -- see https://github.com/alacritty/alacritty/blob/master/INSTALL.md
brew_casks=("docker")
for cask in "${brew_casks[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        echo "[INFO] $cask is already installed."
    else
        echo "[INFO] Installing $cask..."
        brew install --cask "$cask" || echo "[WARN] Failed to install $cask, continuing..."
    fi
done

if ! [ -d "/Applications/Alacritty.app" ] && ! command -v alacritty &>/dev/null; then
    echo "[WARN] Alacritty not found. Install it manually (see INSTALL.md link in setup.sh)."
fi

#TODO: Install Emacs + Doom Emacs (git clone https://github.com/doomemacs/doomemacs ~/.config/emacs && ~/.config/emacs/bin/doom install)
#TODO: Install Latest Golang

# --- Nerd Font ---
FONT_DIR="$HOME/Library/Fonts"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
if compgen -G "$FONT_DIR/JetBrainsMono*.ttf" >/dev/null; then
    echo "[INFO] JetBrainsMono Nerd Font already installed, skipping..."
else
    echo "[INFO] Installing JetBrainsMono Nerd Font..."
    mkdir -p "$FONT_DIR"
    tmp_zip="$(mktemp -t JetBrainsMono).zip"
    curl -fLo "$tmp_zip" "$FONT_URL"
    unzip -o "$tmp_zip" -d "$FONT_DIR"
    rm -f "$tmp_zip"
fi

# --- Stow ---
echo "[INFO] Stowing macOS configurations..."
cd "$DOTFILES_DIR"
stow -t "$HOME" macos

echo "[INFO] Setup complete!"
