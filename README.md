# Dotfiles

macOS-only dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

```sh
./setup.sh          # bootstrap Homebrew, packages, font, then stow
stow -t ~ macos     # (re)link configs only
```

## Layout

| Path | Target |
|---|---|
| `macos/.zshrc` | `~/.zshrc` |
| `macos/.tmux.conf` | `~/.tmux.conf` |
| `macos/.config/doom` | Doom Emacs user config (Doom itself is cloned to `~/.config/emacs`, not tracked) |
| `macos/.config/nvim` | Neovim (kept during the move to Doom) |
| `macos/.config/alacritty` | Alacritty |
| `macos/.config/lazygit` | lazygit |
| `macos/.config/git` | git config + global ignore |

`archive/` holds retired configs (Arch/Omarchy, Debian, iTerm2, old multi-OS setup). Nothing in it is stowed.
