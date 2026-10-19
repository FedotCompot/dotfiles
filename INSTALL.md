# Arch + Hyprland install playbook

End-to-end recipe for reinstalling (or cloning the setup to another box).
Designed to be run **from the Arch ISO**, chrooted into the new system —
clone this repo, run the two scripts, reboot, done.

Everything that *can* live in a config file already lives in this repo's
symlinked configs (`config/hypr/`, `config/waybar/`, `home/.inputrc`, …),
so this guide only covers what has to happen *before* those configs apply:
partitioning choices, the chroot dance, and a handful of post-boot manual
steps (Timeshift first run, Claude Code login).

## Contents

1. [Base install (archinstall)](#1-base-install-archinstall)
2. [Apply the dotfiles from chroot](#2-apply-the-dotfiles-from-chroot)
3. [First boot — manual one-time steps](#3-first-boot--manual-one-time-steps)
4. [Notes & gotchas (the "why")](#4-notes--gotchas-the-why)

---

## 1. Base install (archinstall)

Boot the latest Arch ISO. Connect (`iwctl` for Wi-Fi, ethernet is automatic),
then run:

```bash
archinstall
```

Walk through the menu. Non-obvious choices:

- **Disk configuration** — wipe the disk, pick **BTRFS** as the filesystem.
  Enable **zstd compression** and accept **default subvolumes** (so a
  snapshot rollback doesn't nuke `/home`).
- **Bootloader: rEFInd** — the boot entrypoint. It scans every ESP for
  kernels and EFI loaders itself, so `linux`, `linux-lts` and any other
  OS show up with no menu config to maintain. `arch-setup.sh` later adds
  GRUB as one more rEFInd entry, purely for `grub-btrfs`'s bootable
  Timeshift snapshots. Snapshot entries boot the *current* kernel from
  the FAT `/boot`; if that kernel is newer than the snapshot its modules
  are missing, so boot in only to run a Timeshift restore.
- **Kernels** — tick `linux` **and** `linux-lts` (LTS is the fallback when
  a mainline update breaks graphics or Docker).
- **Profile** — minimal. We bring our own desktop.
- **Keyboard layout** — US is fine for the installer; Hyprland config
  overrides it later.

Set root password, create the user, finish. **Don't reboot yet** — stay in
the live ISO so we can run the dotfiles scripts from the chroot.

## 2. Apply the dotfiles from chroot

Still in the Arch ISO, with the new system mounted at `/mnt`:

```bash
# A minimal profile ships without git
arch-chroot /mnt pacman -S --needed git

# Drop into the new system as your user (a login shell, so HOME/USER are yours)
arch-chroot /mnt su - <username>

git clone https://github.com/FedotCompot/dotfiles ~/code/dotfiles
cd ~/code/dotfiles

./install.sh             # symlink configs into $HOME and $HOME/.config
./arch-setup.sh          # multilib + pikaur + every pacman/aur package + groups
```

`arch-setup.sh` is idempotent (`--needed` everywhere, group-membership
checks). What it does:

1. Enables `[multilib]` in `/etc/pacman.conf`.
2. Bootstraps `pikaur` from AUR (only if missing).
3. Installs everything in `pacman.txt` (official repos) and `aur.txt` (AUR),
   importing the PGP keys AUR packages declare in `validpgpkeys` first
   (makepkg only verifies them, and pikaur aborts on an unknown key).
   Packages in `aur-manual.txt` are skipped: their sources need a manual
   download, and one failed build aborts pikaur's whole batch.
4. Adds the user to every group listed in `usergroups.txt` (skips groups
   whose owning package isn't installed yet).
5. Installs GRUB onto the ESP with `--no-nvram`, so rEFInd stays first in
   the boot order and lists GRUB as an entry. Sets `GRUB_TOP_LEVEL` to
   mainline (`grub-mkconfig` version-sorts `linux-lts` first).
6. Installs `@anthropic-ai/claude-code` globally via bun.

System services are deliberately **not** enabled here — they're enabled
from `first-login.sh` after the first real boot, where `enable --now` is
safe and there's no risk of yanking an active session with sddm.

`install.sh` runs first so `pikaur.conf.template` is seeded before pikaur
writes its own default. It walks `home/` and `config/` and symlinks every
tracked file into `$HOME` / `$HOME/.config`, moving any pre-existing files
into `~/.dotfiles-backup/<timestamp>/` so nothing is lost. `--dry-run`
previews without touching anything.

Exit the chroot and reboot:

```bash
exit
reboot
```

The reboot drops you at a TTY login (sddm isn't enabled yet). Log in as
your user — `first-login.sh` flips on the display manager next.

## 3. First boot — run `first-login.sh`

From the TTY login on the first boot:

```bash
~/code/dotfiles/first-login.sh
sudo reboot   # so sddm starts and group changes apply
```

It's idempotent. What it does:

1. Enables system services: `NetworkManager`, `bluetooth`, `cups`,
   `cronie` (runs Timeshift's boot schedule),
   `docker`, `grub-btrfsd` (with `enable --now`), and `sddm`
   (`enable` only — `--now` would yank the TTY session). `grub-btrfsd`
   gets a drop-in switching it to `--timeshift-auto`; the stock unit
   watches `/.snapshots`, which doesn't exist without snapper.
   Also turns on `ufw` (inbound dropped except WinBox `8291/tcp` and
   MikroTik discovery `5678/udp`, `20561/udp`) and enables the
   `hyprmoncfgd` user service that applies `config/hyprmoncfg/` profiles.
2. Sets `org.gnome.desktop.interface color-scheme` to `prefer-dark` so
   Firefox/Electron pick up the XDG dark hint.
3. Writes a few user `.desktop` entries into
   `~/.local/share/applications/` (can't be tracked dotfiles — they have
   to be generated against system files or runtime-resolved paths):
   - `com.microsoft.VSCode.desktop` with Wayland flags appended to `Exec=`
     (see [§4](#4-notes--gotchas-the-why)).
   - `helium-personal.desktop` + `helium-work.desktop` — separate
     `--user-data-dir` profiles with distinct `StartupWMClass` so Hyprland
     window rules can target them independently.
   - `claude-code-url-handler.desktop` — registers `claude-cli://` so the
     browser can deep-link into Claude Code (`Exec=` points at the real
     binary `readlink -f`'d from `command -v claude`, not the bun wrapper).
4. Writes a minimal `/etc/timeshift/timeshift.json` in BTRFS mode if one
   doesn't exist yet, then makes sure `btrfs_mode` is `true` and
   `backup_device_uuid` is the root filesystem's (without it
   `timeshift --list` shows no snapshots).
   `timeshift-autosnap` is a no-op without this — its pacman hook would
   silently fail to take pre-update snapshots.
5. Takes a baseline Timeshift snapshot tagged `post-install baseline`.
6. Prints the things still requiring manual action:
   - `claude` — first run opens a browser for OAuth.
   - Bluetooth pairing via `blueman`.
   - Printers via the CUPS web UI (`http://localhost:631`).

If you want a richer snapshot schedule than the boot-only default
(e.g. 1 daily, 2 boot), open the Timeshift GUI once and tweak — the
script only sets the minimum `timeshift-autosnap` needs.

## 4. Notes & gotchas (the "why")

Context for choices baked into the configs and package lists. Useful when
something looks weird and you need to know whether to touch it.

### Keyboard

`config/hypr/input.lua` includes `nodeadkeys:false` in `kb_options` to
keep `'`, `"`, and `` ` `` from behaving as dead keys under the `intl`
variant.

### Electron / Wayland blur

By default Electron apps launch under **XWayland** and render at 1× then
get stretched — everything looks fuzzy. Two layers of fix in
`config/hypr/hyprland.lua`:

- `ELECTRON_OZONE_PLATFORM_HINT=wayland` and `NIXOS_OZONE_WL=1` cover most
  apps globally.
- `visual-studio-code-bin` ignores `~/.config/code-flags.conf`, so its
  Wayland flags have to go on the `Exec=` line of a local override at
  `~/.local/share/applications/com.microsoft.VSCode.desktop` (copy from
  `/usr/share/applications/com.microsoft.VSCode.desktop`, append
  `--ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations`,
  then `update-desktop-database ~/.local/share/applications/`).

Do **not** add `--enable-wayland-ime` to VSCode — the IME swallows special
keys like the backtick and breaks shortcuts.

Verify a running app's mode with:

```bash
hyprctl clients | grep -E "class|xwayland"
```

`xwayland: 0` = native Wayland. `xwayland: 1` = still on the compatibility
layer (something didn't take).

### VSCode: use the Microsoft binary

`visual-studio-code-bin` (AUR), not the open-source `code` package — only
the Microsoft binary has working **Remote - SSH** and **Dev Containers**
extensions (license-gated).

### Skip Flameshot

Flameshot doesn't work reliably on Hyprland (window tiles wrong,
multi-monitor breaks, clipboard fails silently). The screenshot binds in
`config/hypr/binds.lua` use `grim` + `slurp` + `grimblast` + `swappy`
instead. Modular, works.

### Skip Homebrew

On Arch, the AUR covers ~everything Homebrew provides, and `linuxbrew`
duplicates `glibc`/`gcc`/etc. under `/home/linuxbrew/`, which causes
occasional weirdness. Only install it if something at work has `brew`
hardcoded in a Makefile.

### Bracketed paste

`home/.inputrc` disables bracketed paste (`set enable-bracketed-paste
off`). Without this, pasting into bash shows
`^[[200~sudo pacman -S …~` instead of the actual command — the terminal
is wrapping pasted text in escape sequences that the shell isn't
unwrapping.

### Dark mode chain

Four layers, all already wired up by the symlinked configs:

- **XDG hint** for Wayland-aware apps (Firefox, Electron): set via
  `gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'`
  on first login if not already.
- **GTK** — `adw-gtk3-dark`, via `nwg-look` config.
- **Qt** — `qt5ct` + `qt6ct` → `kvantum` dark.
- **Env vars** in `config/hypr/hyprland.lua`: `GTK_THEME=adw-gtk3-dark`,
  `QT_QPA_PLATFORMTHEME=qt6ct`, `QT_STYLE_OVERRIDE=kvantum`.
