#!/usr/bin/env bash
#
# Symlinks tracked configs into their real locations.
# Existing files are moved aside into a timestamped backup dir.
#
# Layout:
#   home/<path>   -> $HOME/<path>
#   config/<name> -> $HOME/.config/<name>

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help)
      echo "Usage: $0 [--dry-run]"
      exit 0
      ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '%s\n' "$*"; }

backup() {
  local target="$1"
  [ -e "$target" ] || [ -L "$target" ] || return 0
  local rel="${target#$HOME/}"
  local dest="$BACKUP_DIR/$rel"
  if [ "$DRY_RUN" -eq 1 ]; then
    say "  backup: $target -> $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
}

link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "  ok:     $dst"
    return 0
  fi
  backup "$dst"
  if [ "$DRY_RUN" -eq 1 ]; then
    say "  link:   $dst -> $src"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  say "  link:   $dst -> $src"
}

say "Dotfiles install (repo: $REPO_DIR)"
[ "$DRY_RUN" -eq 1 ] && say "(dry-run — no changes will be made)"
say "Backup dir: $BACKUP_DIR"

# Top-level files in $HOME
for f in .bash_profile .bashrc .bashrc.bak .gitconfig .inputrc; do
  link "$REPO_DIR/home/$f" "$HOME/$f"
done

# Each top-level entry under config/ -> ~/.config/<name>
for entry in "$REPO_DIR"/config/*; do
  name="$(basename "$entry")"
  link "$entry" "$HOME/.config/$name"
done

say
say "Done."
if [ -d "$BACKUP_DIR" ]; then
  say "Existing files were moved to: $BACKUP_DIR"
fi
