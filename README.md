# dotfiles

My Arch + Hyprland desktop config, gathered for fast replication on a fresh
install.

## Layout

```
home/                       -> $HOME/
  .bash_profile
  .bashrc                   (the mybash bashrc, unpacked from upstream)
  .bashrc.bak               (snapshot of the pre-mybash bashrc)
  .gitconfig
  .inputrc

config/                     -> $HOME/.config/
  starship.toml             (prompt config, unpacked from mybash)
  hypr/                     Hyprland (conf + lua modules + scripts)
  hyprmoncfg/               hyprmon monitor profile
  waybar/                   Waybar (config, style, mediaplayer.py, power menu)
  swaync/                   Sway notification center
  btop/                     btop system monitor
  fontconfig/               font rules
  nwg-look/                 GTK theme picker
  qt6ct/  QtProject.conf    Qt theming
  Code/User/                VS Code settings + keybindings
  autostart/                XDG autostart entries (ferdium)
  kdeglobals kiorc ktrashrc kwalletrc dolphinrc
  mimeapps.list             default app handlers
  pavucontrol.ini
  pikaur.conf
```

## Install on a fresh box

```bash
git clone <this-repo> ~/code/dotfiles
cd ~/code/dotfiles

./arch-setup.sh          # multilib + pikaur + every package
./install.sh --dry-run   # preview dotfile symlinks
./install.sh             # apply dotfile symlinks
```

### `arch-setup.sh`

Enables `[multilib]` in `/etc/pacman.conf`, builds **pikaur** from AUR, then
installs everything listed in `pacman.txt` (official repos) and `aur.txt`
(AUR). The package lists are plain text, one package per line; blank lines and
`#` comments are ignored. Re-running is idempotent — `--needed` skips packages
already installed.

Regenerate the lists from a live box with:

```bash
pacman -Qqen > pacman.txt   # explicit native packages
pacman -Qqem > aur.txt      # explicit AUR/foreign packages
```

### `install.sh`

Symlinks tracked files into their real locations and moves any pre-existing
files into `~/.dotfiles-backup/<timestamp>/` so nothing is lost.

## What's deliberately not in here

- Browser/IM state: Ferdium, Helium, Vesktop, Discord — too much runtime data.
- Auth/secrets: `~/.ssh`, `~/.gnupg`, `~/.config/gh`, `~/.claude.json`.
- App runtime/cache: dconf, kwallet contents, pulse, mozilla, dotnet, freelens,
  navicat, balenaEtcher, etc.
- Empty config dirs (kitty, helix, mpv, gtk-3.0) — nothing to back up yet.
