#!/usr/bin/env bash
#
# Bootstraps a fresh Arch box:
#   1. Enables [multilib] in /etc/pacman.conf
#   2. Installs pikaur (AUR helper) from source
#   3. Installs packages listed in pacman.txt (official repos) and aur.txt (AUR)
#
# Lists are plain text, one package per line. Blank lines and `#` comments
# are ignored. Re-running is safe — already-installed packages are skipped.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACMAN_LIST="$SCRIPT_DIR/pacman.txt"
AUR_LIST="$SCRIPT_DIR/aur.txt"
GROUPS_LIST="$SCRIPT_DIR/usergroups.txt"

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "Run as your normal user — the script invokes sudo where needed." >&2
  exit 1
fi

step() { printf '\n==> %s\n' "$*"; }

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
  trap 'rm -rf "$tmp"' EXIT
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
pkgs=$(read_list "$AUR_LIST")
if [ -n "$pkgs" ]; then
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

# 5. Claude Code (bun global) ----------------------------------------------------
step "Installing Claude Code CLI"
if command -v claude >/dev/null 2>&1; then
  echo "  already installed"
else
  bun install -g @anthropic-ai/claude-code
fi

step "Done"
