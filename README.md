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
./install.sh --dry-run   # preview
./install.sh             # apply
```

`install.sh` symlinks tracked files into their real locations and moves any
pre-existing files into `~/.dotfiles-backup/<timestamp>/` so nothing is lost.

## What's deliberately not in here

- Browser/IM state: Ferdium, Helium, Vesktop, Discord — too much runtime data.
- Auth/secrets: `~/.ssh`, `~/.gnupg`, `~/.config/gh`, `~/.claude.json`.
- App runtime/cache: dconf, kwallet contents, pulse, mozilla, dotnet, freelens,
  navicat, balenaEtcher, etc.
- Empty config dirs (kitty, helix, mpv, gtk-3.0) — nothing to back up yet.

## Required packages (Hyprland desktop)

Not exhaustive — install as needed:

```
hyprland hyprlock hyprpaper waybar swaync ghostty btop
qt6ct nwg-look fontconfig starship
ferdium-bin  # AUR (autostart entry references it)
```

The mybash bootstrap is run by sourcing `~/.bashrc` (which after install
resolves to `~/.local/share/mybash/.bashrc`).
