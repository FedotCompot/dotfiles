# dotfiles

My Arch + Hyprland desktop config, gathered for fast replication on a fresh
install.

## Layout

```
home/                       -> $HOME/
  .bash_profile
  .bashrc                   (the mybash bashrc, unpacked from upstream)
  .bashrc.bak               (snapshot of the pre-mybash bashrc)
  .gitconfig.template       (seeded; fill in [user] locally after install)
  .inputrc

config/                     -> $HOME/.config/
  starship.toml             (prompt config, unpacked from mybash)
  hypr/                     Hyprland (conf + lua modules + scripts)
  hyprmoncfg/               hyprmon monitor profile
  waybar/                   Waybar (config, style, mediaplayer.py, power menu)
  swaync/                   Sway notification center
  btop/                     btop system monitor
  satty/                    satty screenshot annotator (built from the fork)
  sunshine/                 sunshine.conf.template (seeded; the web UI rewrites it)
  systemd/user/             waybar units, rclone-gdrive@ Google Drive mounts
  fontconfig/               font rules
  nwg-look/                 GTK theme picker
  qt6ct/                    Qt theming
  Code/User/                VS Code settings + keybindings
  autostart/                XDG autostart entries (ferdium)
  kdeglobals kiorc kwalletrc dolphinrc
  mimeapps.list             default app handlers
  pavucontrol.ini
  pikaur.conf.template      (seeded; pikaur rewrites paths locally)

system/systemd/             -> /etc/systemd/system/ (copied by first-login.sh)
  aur-autoupdate@.{service,timer}  daily update of selected AUR packages
  grub-btrfsd.service.d/     watch Timeshift's snapshot dir, not /.snapshots
```

Files ending in `.template` are **copied** on first install instead of
symlinked, and skipped on later runs — see [`install.sh`](#installsh) below.

## Install on a fresh box

```bash
git clone <this-repo> ~/code/dotfiles
cd ~/code/dotfiles

./install.sh --dry-run   # preview dotfile symlinks
./install.sh             # apply dotfile symlinks (first, so pikaur.conf is seeded)
./arch-setup.sh          # multilib + pikaur + every package + user groups
# reboot, then on first TTY login:
./first-login.sh         # enable services, baseline snapshot, etc.
```

For the full Arch install walkthrough (archinstall + BTRFS snapshots,
Hyprland/Wayland gotchas, Electron blur fix, theming, etc.) see
[INSTALL.md](INSTALL.md).

### `arch-setup.sh`

Enables `[multilib]` in `/etc/pacman.conf`, builds **pikaur** from AUR,
installs everything listed in `pacman.txt` (official repos) and `aur.txt`
(AUR), and adds the user to every group in `usergroups.txt`. The lists are
plain text, one entry per line; blank lines and `#` comments are ignored.
Re-running is idempotent — `--needed` skips packages already installed,
and group/membership additions are guarded by existence checks.

Regenerate the package lists from a live box with:

```bash
pacman -Qqen > pacman.txt   # explicit native packages
pacman -Qqem > aur.txt      # explicit AUR/foreign packages
```

AUR packages listed in `aur-manual.txt` (sources behind a login, like
`vmware-vmrc`) are skipped by `arch-setup.sh`, which prints how to build
them by hand at the end.

### `install.sh`

Symlinks tracked files into their real locations and moves any pre-existing
files into `~/.dotfiles-backup/<timestamp>/` so nothing is lost.

Files ending in `.template` (currently `home/.gitconfig.template` and
`config/pikaur.conf.template`) get a different treatment: they're **copied**
into place with the `.template` suffix stripped, and only when the target
doesn't already exist. This is for files that need to diverge per-machine
without showing up as working-tree changes — git identity in `.gitconfig`,
and the `cachepath`/`datapath` lines pikaur rewrites with the local user's
home on every run.

### `first-login.sh`

Run once after the first real boot (see [INSTALL.md §3](INSTALL.md#3-first-boot--run-first-loginsh)).
Enables system services, sets the XDG dark-mode hint, writes the VSCode
`.desktop` Wayland override, configures Timeshift for BTRFS, and takes a
baseline snapshot. Idempotent.

It also installs and enables `aur-autoupdate@$USER.timer`, which once a day
runs `pikaur -S --needed` as root for the packages listed in
`system/systemd/aur-autoupdate@.service`. The builds run as your user. To
change the list, edit that unit and re-run `./first-login.sh` to copy it
into `/etc`. Logs: `journalctl -u aur-autoupdate@$USER`.

## Google Drive in Thunar

Each Google account is an rclone remote mounted at `~/GoogleDrive/<name>`
by the `rclone-gdrive@<name>` user unit, and bookmarked in Thunar's side
pane. Like the Drive app, each mount holds `My Drive`, `Shared with me` and
`Shared drives/<drive>`; `gdrive-remotes` rebuilds that tree (the
`<name>_all` combine remote) on every mount start, so newly joined shared
drives show up after the next login or
`systemctl --user restart rclone-gdrive@<name>`. Like the Drive app, the
mount fetches the whole folder tree in the background when it starts (a few
minutes for a big account) and keeps it cached, so Thunar opens folders
instantly; rclone checks for changes made elsewhere every minute. Add one
per account:

```bash
gdrive-add personal   # opens the browser to sign in
gdrive-add work
```

Tokens live in `~/.config/rclone/rclone.conf`, which stays out of the repo,
so re-run `gdrive-add` for each account on a new box. To drop one:
`systemctl --user disable --now rclone-gdrive@<name>`, then
`rclone config delete` for `<name>`, `<name>_all` and
`<name>_shared_drives`, and remove its line from
`~/.config/gtk-3.0/bookmarks`.

## What's deliberately not in here

- Browser/IM state: Ferdium, Helium, Vesktop, Discord — too much runtime data.
- Auth/secrets: `~/.ssh`, `~/.gnupg`, `~/.config/gh`, `~/.claude.json`.
- App runtime/cache: dconf, kwallet contents, pulse, mozilla, dotnet, freelens,
  navicat, balenaEtcher, etc.
- Empty config dirs (kitty, helix, mpv, gtk-3.0) — nothing to back up yet.
- KDE/Qt files keyed by absolute home path (`ktrashrc`, `QtProject.conf`) —
  section headers / `lastVisited` paths bake in the original username, so KDE
  ignores them on any other user. The apps regenerate sensible defaults.

## Post-install: set your git identity

The `home/.gitconfig.template` seed copied to `~/.gitconfig` deliberately
ships **without** `user.name` / `user.email` so it never silently commits
under someone else's identity. Set yours after `./install.sh`:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```
