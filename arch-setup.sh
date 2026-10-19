#!/usr/bin/env bash
#
# Bootstraps a fresh Arch box:
#   1. Enables [multilib] in /etc/pacman.conf
#   2. Installs pikaur (AUR helper) from source
#   3. Installs packages listed in pacman.txt (official repos) and aur.txt (AUR)
#   4. Adds the user to the groups in usergroups.txt
#   5. Installs GRUB next to rEFInd, for grub-btrfs snapshot entries
#   6. Builds satty from the FedotCompot/Satty fork into ~/.local
#   7. Installs Claude Code via bun
#
# Lists are plain text, one package per line. Blank lines and `#` comments
# are ignored. Re-running is safe — already-installed packages are skipped.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACMAN_LIST="$SCRIPT_DIR/pacman.txt"
AUR_LIST="$SCRIPT_DIR/aur.txt"
AUR_MANUAL_LIST="$SCRIPT_DIR/aur-manual.txt"
GROUPS_LIST="$SCRIPT_DIR/usergroups.txt"

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "Run as your normal user — the script invokes sudo where needed." >&2
  exit 1
fi
# arch-chroot -u keeps root's HOME and USER
if [ "${USER:-}" != "$(id -un)" ] || [ "$HOME" != "$(getent passwd "$(id -un)" | cut -d: -f6)" ]; then
  echo "HOME/USER belong to someone else — enter the chroot with: arch-chroot /mnt su - $(id -un)" >&2
  exit 1
fi

step() { printf '\n==> %s\n' "$*"; }

# gpg daemons killed with the chroot leave keyring locks nothing can clear
tmp=""
cleanup() {
  gpgconf --kill all 2>/dev/null || true
  [ -z "$tmp" ] || rm -rf "$tmp"
}
trap cleanup EXIT

# Strip comments and blank lines from a package list
read_list() {
  local f="$1"
  [ -f "$f" ] || return 0
  sed -E 's/[[:space:]]*#.*$//; /^[[:space:]]*$/d' "$f"
}

# 1. Multilib ------------------------------------------------------------------
step "Configuring multilib"
if grep -q '^\[multilib\]' /etc/pacman.conf; then
  echo "  already enabled"
elif grep -q '^#\[multilib\]' /etc/pacman.conf; then
  echo "  uncommenting [multilib] section"
  sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
  sudo pacman -Sy
else
  echo "  appending [multilib] section"
  printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
  sudo pacman -Sy
fi

# 2. Pikaur --------------------------------------------------------------------
step "Installing pikaur"
if command -v pikaur >/dev/null 2>&1; then
  echo "  already installed"
else
  sudo pacman -S --needed --noconfirm base-devel git
  tmp="$(mktemp -d)"
  git clone --depth=1 https://aur.archlinux.org/pikaur.git "$tmp/pikaur"
  ( cd "$tmp/pikaur" && makepkg -fsri --noconfirm )
fi

# 3. Packages ------------------------------------------------------------------
step "Installing pacman packages from $(basename "$PACMAN_LIST")"
pkgs=$(read_list "$PACMAN_LIST")
if [ -n "$pkgs" ]; then
  # shellcheck disable=SC2086
  sudo pacman -S --needed --noconfirm $pkgs
else
  echo "  (list empty or missing — skipping)"
fi

step "Installing AUR packages from $(basename "$AUR_LIST")"
manual=$(read_list "$AUR_MANUAL_LIST")
pkgs=$(read_list "$AUR_LIST" | awk -v skip="$manual" 'BEGIN { split(skip, a, "\n"); for (i in a) s[a[i]] } !($0 in s)')
if [ -n "$pkgs" ]; then
  # makepkg checks validpgpkeys but never fetches them
  # shellcheck disable=SC2086
  query=$(printf '&arg[]=%s' $pkgs)
  bases=$(curl -fsS "https://aur.archlinux.org/rpc/v5/info?${query#&}" | jq -r '.results[].PackageBase' | sort -u)
  for base in $bases; do
    curl -fsS "https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=$base" | sed -n 's/^[[:space:]]*validpgpkeys = //p'
  done | sort -u | while read -r key; do
    if gpg --list-keys "$key" >/dev/null 2>&1; then
      echo "  PGP key $key already imported"
    else
      gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$key"
    fi
  done
  # shellcheck disable=SC2086
  pikaur -S --needed --noconfirm $pkgs
else
  echo "  (list empty or missing — skipping)"
fi

# 4. User groups -----------------------------------------------------------------
step "Adding $USER to supplementary groups from $(basename "$GROUPS_LIST")"
current=$(id -nG "$USER" | tr ' ' '\n')
while IFS= read -r g; do
  [ -z "$g" ] && continue
  if ! getent group "$g" >/dev/null 2>&1; then
    echo "  $g group missing — skipping (package owning it not installed yet?)"
    continue
  fi
  if printf '%s\n' "$current" | grep -qx "$g"; then
    echo "  $g already a member"
  else
    sudo usermod -aG "$g" "$USER"
    echo "  $g added"
  fi
done < <(read_list "$GROUPS_LIST")

# 5. GRUB, chained from rEFInd ----------------------------------------------------
# --no-nvram keeps rEFInd first; it picks GRUB up from the ESP on its own
step "Installing GRUB as a rEFInd entry"
esp=$(bootctl --print-esp-path 2>/dev/null || echo /boot)
if [ ! -d /sys/firmware/efi ]; then
  echo "  not a UEFI boot — skipping"
else
  if ! grep -q '^GRUB_TOP_LEVEL=' /etc/default/grub; then
    # grub-mkconfig version-sorts linux-lts above linux
    echo 'GRUB_TOP_LEVEL="/boot/vmlinuz-linux"' | sudo tee -a /etc/default/grub >/dev/null
  fi
  # archinstall gave only rEFInd the LUKS unlock parameters
  luks=$(sudo sed -n '1s/^"[^"]*" *"\(.*\)"$/\1/p' /boot/refind_linux.conf 2>/dev/null \
    | tr ' ' '\n' | grep -E '^(rd\.luks\.|cryptdevice=)' | paste -sd ' ' || true)
  if [ -n "$luks" ] && ! grep -qF "$luks" /etc/default/grub; then
    sudo sed -i "s|^GRUB_CMDLINE_LINUX=\"\(.*\)\"|GRUB_CMDLINE_LINUX=\"\1 $luks\"|" /etc/default/grub
    echo "  LUKS parameters: $luks"
  fi
  if sudo test -f "$esp/EFI/GRUB/grubx64.efi"; then  # ESP is root-only
    echo "  already on the ESP"
  else
    sudo grub-install --target=x86_64-efi --efi-directory="$esp" --bootloader-id=GRUB --no-nvram
  fi
  sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# 6. Satty from the fork ------------------------------------------------------------
step "Building satty from FedotCompot/Satty"
SATTY_DIR="$HOME/code/Satty"
if [ -x "$HOME/.local/bin/satty" ]; then
  echo "  already installed"
else
  sudo pacman -S --needed --noconfirm gtk4 libadwaita
  if [ ! -d "$SATTY_DIR" ]; then
    git clone https://github.com/FedotCompot/Satty.git "$SATTY_DIR"
    git -C "$SATTY_DIR" remote add upstream https://github.com/Satty-org/Satty
  fi
  rustup default >/dev/null 2>&1 || rustup default stable
  make -C "$SATTY_DIR" install PREFIX="$HOME/.local"
fi

# 7. Claude Code (bun global) ----------------------------------------------------
step "Installing Claude Code CLI"
# chroot shell predates .bashrc; keep bun's bin on .bash_profile's PATH
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
if [ -x "$XDG_CACHE_HOME/.bun/bin/claude" ]; then
  echo "  already installed"
else
  bun install -g @anthropic-ai/claude-code
fi

step "Done"
for p in $manual; do
  echo "  $p is manual (see $(basename "$AUR_MANUAL_LIST")): git clone https://aur.archlinux.org/$p.git, drop the source in, makepkg -si"
done
