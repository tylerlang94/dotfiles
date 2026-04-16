#!/usr/bin/env bash
set -euo pipefail

CURRENT_USER="${SUDO_USER:-$USER}"
echo "Current user: $CURRENT_USER"

if groups "$CURRENT_USER" | grep -qw sudo; then
    echo "$CURRENT_USER is already in the sudo group."
else
    echo "Adding $CURRENT_USER to sudo group..."
    sudo usermod -aG sudo "$CURRENT_USER"
fi

echo "Updating system..."
sudo apt update -y
sudo apt upgrade -y

# PACKAGES I HAVE ON EVERY INSTALL
packages=("luarocks" "git" "stow" "tmux" "ca-certificates" "curl" "gnupg" "lsb-release" "nodejs" "npm" "ripgrep" "gopls")

for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        echo "$pkg is already installed."
    else
        echo "Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
done

# --- Docker setup ---
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

# Install Docker packages
docker_packages=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")
for pkg in "${docker_packages[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        echo "$pkg is already installed."
    else
        echo "Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
done

sudo systemctl enable docker
sudo systemctl start docker

if groups "$CURRENT_USER" | grep -qw docker; then
    echo "$CURRENT_USER is already in the docker group."
else
    echo "Adding $CURRENT_USER to docker group..."
    sudo usermod -aG docker "$CURRENT_USER"
    echo "You may need to log out and log back in for docker group changes to take effect."
fi

#TODO: Install Latest NeoVim

# NERD_FONTS
FONT_NAME="JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"

if fc-list | grep -qi "$FONT_NAME"; then
    echo "$FONT_NAME already installed, skipping..."
else
    echo "Installing $FONT_NAME"
    mkdir -p "$FONT_DIR"
    cd "$FONT_DIR"
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip
    rm JetBrainsMono.zip

    fc-cache -fv
    echo "$FONT_NAME installed"
fi

#TODO: Install Lastest Golang

#TODO: Make a checkbox option for the different packages in dotfiles.
#      This will make it so I don't have to edit this line for different OS's or when adding another package.
cd ~/dotfiles/ && stow common nvim debian

echo "Setup complete!"
