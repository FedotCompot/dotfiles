#!/usr/bin/env bash
#
# Symlinks tracked configs into their real locations, *file by file*.
# Parent directories on the target side are created as real directories so
# that apps writing state alongside config (VS Code's Cache/, etc.) don't
# leak into the repo.
#
# Layout:
#   home/<path>            -> $HOME/<path>            (symlink)
#   config/<path>          -> $HOME/.config/<path>    (symlink)
#   home/<path>.template   -> $HOME/<path>            (copy, skipped if exists)
#   config/<path>.template -> $HOME/.config/<path>    (copy, skipped if exists)
#
# `.template` files seed a fresh box with the shape of a file that's meant
# to diverge per-machine (.gitconfig user identity, pikaur.conf paths that
# the tool itself rewrites). They're copied — never symlinked — so local
# edits stay outside the repo.
#
# Existing files are moved aside into a timestamped backup dir.

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

# Copy a template into place only if the destination doesn't already exist.
# Used for files the user will edit locally (.gitconfig identity, pikaur paths).
seed() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    say "  keep:   $dst (template skipped, file exists)"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    say "  seed:   $dst <- $src"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  say "  seed:   $dst <- $src"
}


say "Dotfiles install (repo: $REPO_DIR)"
[ "$DRY_RUN" -eq 1 ] && say "(dry-run — no changes will be made)"
say "Backup dir: $BACKUP_DIR"

# Pass 1: symlink every regular tracked file (skipping .template seeds —
# those get a second pass so they defer to any symlink that was just made).
while IFS= read -r -d '' src; do
  rel="${src#$REPO_DIR/home/}"
  link "$src" "$HOME/$rel"
done < <(find "$REPO_DIR/home" -type f ! -name '*.template' -print0)

while IFS= read -r -d '' src; do
  rel="${src#$REPO_DIR/config/}"
  link "$src" "$HOME/.config/$rel"
done < <(find "$REPO_DIR/config" -type f ! -name '*.template' -print0)

# Pass 2: seed .template files into place only if the target doesn't exist.
while IFS= read -r -d '' src; do
  rel="${src#$REPO_DIR/home/}"
  seed "$src" "$HOME/${rel%.template}"
done < <(find "$REPO_DIR/home" -type f -name '*.template' -print0)

while IFS= read -r -d '' src; do
  rel="${src#$REPO_DIR/config/}"
  seed "$src" "$HOME/.config/${rel%.template}"
done < <(find "$REPO_DIR/config" -type f -name '*.template' -print0)

say
say "Done."
if [ -d "$BACKUP_DIR" ]; then
  say "Existing files were moved to: $BACKUP_DIR"
fi
