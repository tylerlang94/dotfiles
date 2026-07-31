#!/usr/bin/env bash
set -euo pipefail

# Detect Operating System
OS="$(uname -s)"
CURRENT_USER="${SUDO_USER:-$USER}"
echo "[INFO] Current user: $CURRENT_USER"
echo "[INFO] Detected OS: $OS"

# --- OS-Specific Sudo / Package Manager Setup ---
if [ "$OS" = "Linux" ]; then
    if groups "$CURRENT_USER" | grep -qw sudo; then
        echo "[INFO] $CURRENT_USER is already in the sudo group."
    else
        echo "[INFO] Adding $CURRENT_USER to sudo group..."
        sudo usermod -aG sudo "$CURRENT_USER"
    fi

    echo "[INFO] Updating system..."
    sudo apt update -y
    sudo apt upgrade -y

    # PACKAGES I HAVE ON EVERY INSTALL (Debian)
    packages=("luarocks" "git" "stow" "tmux" "ca-certificates" "curl" "gnupg" "lsb-release" "nodejs" "npm" "ripgrep" "gopls")

    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            echo "[INFO] $pkg is already installed."
        else
            echo "[INFO] Installing $pkg..."
            sudo apt install -y "$pkg"
        fi
    done

elif [ "$OS" = "Darwin" ]; then
    echo "[INFO] Setting up macOS environment..."

    # Ensure Homebrew is installed
    if ! command -v brew &>/dev/null; then
        echo "[INFO] Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon / Intel Macs
        if [ -d "/opt/homebrew/bin" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -d "/usr/local/bin" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        echo "[INFO] Updating Homebrew..."
        brew update
    fi

    # PACKAGES I HAVE ON EVERY INSTALL (macOS via Brew)
    brew_packages=("luarocks" "git" "stow" "tmux" "node" "ripgrep" "gopls")

    for pkg in "${brew_packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            echo "[INFO] $pkg is already installed."
        else
            echo "[INFO] Installing $pkg..."
            brew install "$pkg"
        fi
    done
fi

# --- Docker setup ---
if [ "$OS" = "Linux" ]; then
    echo "Setting up Docker repository..."

    sudo install -m 0755 -d /etc/apt/keyrings

    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    DOCKER_LIST_FILE="/etc/apt/sources.list.d/docker.list"
    if [ ! -f "$DOCKER_LIST_FILE" ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee "$DOCKER_LIST_FILE" >/dev/null
    fi

    sudo apt update -y

    docker_packages=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")
    for pkg in "${docker_packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            echo "[INFO] $pkg is already installed."
        else
            echo "[INFO] Installing $pkg..."
            sudo apt install -y "$pkg"
        fi
    done

    sudo systemctl enable docker
    sudo systemctl start docker

    if groups "$CURRENT_USER" | grep -qw docker; then
        echo "[INFO] $CURRENT_USER is already in the docker group."
    else
        echo "[INFO] Adding $CURRENT_USER to docker group..."
        sudo usermod -aG docker "$CURRENT_USER"
        echo "[WARNING] You may need to log out and log back in for docker group changes to take effect."
    fi

elif [ "$OS" = "Darwin" ]; then
    if ! command -v docker &>/dev/null; then
        echo "[INFO] Installing Docker Desktop for Mac..."
        brew install --cask docker
    else
        echo "[INFO] Docker is already installed."
    fi
fi

#TODO: Install Latest NeoVim

# --- Nerd Fonts ---
FONT_DIR="$HOME/.local/share/fonts"
if [ "$OS" = "Darwin" ]; then
    # macOS standard user font directory
    FONT_DIR="$HOME/Library/Fonts"
fi

FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

if compgen -G "$FONT_DIR/JetBrainsMonoNerdFont-*.ttf" >/dev/null || compgen -G "$FONT_DIR/JetBrainsMono*.ttf" >/dev/null; then
    echo "[INFO] JetBrainsMono Nerd Font already installed, skipping..."
else
    echo "Installing JetBrainsMono Nerd Font"
    mkdir -p "$FONT_DIR"

    tmp_zip="/tmp/JetBrainsMono.zip"
    curl -fLo "$tmp_zip" "$FONT_URL"
    unzip -o "$tmp_zip" -d "$FONT_DIR"
    rm -f "$tmp_zip"

    if [ "$OS" = "Linux" ]; then
        fc-cache -fv
    fi
    echo "[INFO] JetBrainsMono Nerd Font installed"
fi

#TODO: Install Latest Golang

#TODO: Make a checkbox option for the different packages in dotfiles.
if [ -d "$HOME/dotfiles" ]; then
    cd ~/dotfiles/
    if [ "$OS" = "Linux" ]; then
        echo "[INFO] Stowing Linux configurations..."
        stow tmux nvim debian
    elif [ "$OS" = "Darwin" ]; then
        echo "[INFO] Stowing macOS configurations..."
        stow tmux nvim macos
    fi
else
    echo "[WARNING] ~/dotfiles directory not found, skipping stow."
fi

echo "[INFO] Setup complete!"
