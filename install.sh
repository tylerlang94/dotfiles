#!/usr/bin/env bash

DOTFILES_DIR=$(pwd)
CONFIG_DST="$HOME/.config"

NVIM_CONFIG_SRC="$DOTFILES_DIR/nvim"
TMUX_CONFIG_SRC="$DOTFILES_DIR/tmux"

BACKUP_DIR="$HOME/BACKUP_DIR"

dt=$(date +"%Y-%m-%d:%H:%M")

echo "Backing up config files"
if [ ! -e "$BACKUP_DIR" ]; then
    echo "$BACKUP_DIR doesn't exist. Creating..."
    mkdir $BACKUP_DIR
fi

if [ -e "$CONFIG_DST/nvim" ]; then
    echo "Moving NVIM to backup directory"
    mv -f $CONFIG_DST/nvim $BACKUP_DIR/nvim$dt
fi

if [ -e "$CONFIG_DST/tmux" ]; then

    echo "Moving TMUX to backup directory"
    mv -f $CONFIG_DST/tmux $BACKUP_DIR/tmux$dt
fi

echo "Copying the config files to $CONFIG_DST"
echo "$NVIM_CONFIG_SRC"
echo "$TMUX_CONFIG_SRC"
cp -R "$NVIM_CONFIG_SRC" "$CONFIG_DST/nvim"
cp -R "$TMUX_CONFIG_SRC" "$CONFIG_DST/tmux"
