#!/usr/bin/env bash
#
# Run once after the first real boot. Handles the manual steps that can't
# (or shouldn't) be done from chroot or via symlinked dotfiles:
#
#   1. Enable system services (kept out of chroot for safety)
#   2. GNOME color-scheme = prefer-dark (XDG hint picked up by Firefox/Electron)
#   3. User .desktop entries:
#        a. VSCode native-Wayland override
#        b. Helium profile launchers (personal + work)
#        c. Claude Code claude-cli:// URL handler
#   4. Timeshift BTRFS-mode config (timeshift-autosnap is a no-op without it)
#   5. Baseline Timeshift snapshot
#   6. Print the remaining manual checklist
#
# Idempotent — safe to re-run.

set -euo pipefail

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "Run as your normal user — the script invokes sudo where needed." >&2
  exit 1
fi

step() { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }

# 1. System services ----------------------------------------------------------
# Done from a real session (not chroot) so `enable --now` is safe for the
# non-display services; sddm is `enable` only so it picks up on next boot
# without yanking the current tty session.
step "Enabling system services"
boot_services=(NetworkManager bluetooth cups docker grub-btrfsd)
for svc in "${boot_services[@]}"; do
  if sudo systemctl is-enabled "$svc" >/dev/null 2>&1; then
    note "$svc already enabled"
  else
    sudo systemctl enable --now "$svc"
    note "$svc enabled + started"
  fi
done
if sudo systemctl is-enabled sddm >/dev/null 2>&1; then
  note "sddm already enabled"
else
  sudo systemctl enable sddm
  note "sddm enabled (will start on next boot)"
fi

# 2. Dark mode hint -----------------------------------------------------------
step "GNOME color-scheme = prefer-dark"
if command -v gsettings >/dev/null 2>&1; then
  current=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "")
  if [ "$current" = "'prefer-dark'" ]; then
    note "already set"
  else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    note "ok"
  fi
else
  note "gsettings unavailable — skipping"
fi

# 3. User .desktop entries ---------------------------------------------------
APPS_DIR="$HOME/.local/share/applications"
mkdir -p "$APPS_DIR"
desktop_dirty=0

# 3a. VSCode native Wayland override.
# code-flags.conf is ignored by visual-studio-code-bin, so the wayland flags
# have to go straight on the Exec= line.
step "VSCode native Wayland .desktop override"
SYS_DESKTOP=/usr/share/applications/code.desktop
USR_DESKTOP="$APPS_DIR/code.desktop"
WL_FLAGS="--ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations"
if [ ! -f "$SYS_DESKTOP" ]; then
  note "$SYS_DESKTOP missing — install visual-studio-code-bin first; skipping"
elif [ -f "$USR_DESKTOP" ] && grep -q 'ozone-platform-hint=wayland' "$USR_DESKTOP"; then
  note "already overridden"
else
  sed -E "s|^(Exec=/usr/bin/code)(.*)( %[FU])$|\\1\\2 ${WL_FLAGS}\\3|" \
    "$SYS_DESKTOP" > "$USR_DESKTOP"
  desktop_dirty=1
  note "ok ($USR_DESKTOP)"
fi

# 3b. Helium browser profile launchers (personal + work).
# Separate --user-data-dir + distinct StartupWMClass so Hyprland window rules
# can target them independently. Each is set as a candidate http(s) handler;
# the actual default is picked by config/mimeapps.list.
write_helium_profile() {
  local label="$1" slug="$2"
  local file="$APPS_DIR/helium-${slug}.desktop"
  local data_dir="$HOME/.config/net.imput.helium-${slug}"
  if [ -f "$file" ]; then
    note "helium-${slug}: already exists — leaving alone"
    return
  fi
  cat > "$file" <<EOF
[Desktop Entry]
Version=1.0
Name=Helium (${label})
GenericName=Web Browser
Comment=Helium browser using the ${label} profile
Exec=helium-browser --class=helium-${slug} --user-data-dir=${data_dir} %U
StartupNotify=true
StartupWMClass=helium-${slug}
Terminal=false
Icon=helium-browser
Type=Application
Categories=Network;WebBrowser;
MimeType=application/pdf;application/xhtml+xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/http;x-scheme-handler/https;
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=New Window
Exec=helium-browser --class=helium-${slug} --user-data-dir=${data_dir}

[Desktop Action new-private-window]
Name=New Incognito Window
Exec=helium-browser --class=helium-${slug} --user-data-dir=${data_dir} --incognito
EOF
  desktop_dirty=1
  note "helium-${slug}: written"
}
step "Helium browser profile launchers"
if ! command -v helium-browser >/dev/null 2>&1; then
  note "helium-browser not installed — skipping"
else
  write_helium_profile "Personal" personal
  write_helium_profile "Work"     work
fi

# 3c. Claude Code claude-cli:// URL handler.
# Browser deep-links into Claude Code (e.g. from the desktop OAuth flow).
# Must point at the real binary, not the bun-generated symlink wrapper, or
# argv parsing of --handle-uri breaks when invoked by xdg-open.
step "Claude Code URL handler (claude-cli://)"
CLAUDE_URL_DESKTOP="$APPS_DIR/claude-code-url-handler.desktop"
if [ -f "$CLAUDE_URL_DESKTOP" ]; then
  note "already exists — leaving alone"
elif ! command -v claude >/dev/null 2>&1; then
  note "claude not on PATH — run arch-setup.sh first; skipping"
else
  real_claude=$(readlink -f "$(command -v claude)")
  cat > "$CLAUDE_URL_DESKTOP" <<EOF
[Desktop Entry]
Name=Claude Code URL Handler
Comment=Handle claude-cli:// deep links for Claude Code
Exec="${real_claude}" --handle-uri %u
Type=Application
NoDisplay=true
MimeType=x-scheme-handler/claude-cli;
EOF
  desktop_dirty=1
  note "written ($CLAUDE_URL_DESKTOP)"
fi

if [ "$desktop_dirty" -eq 1 ]; then
  update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
fi

# 4. Timeshift BTRFS mode -----------------------------------------------------
step "Timeshift BTRFS mode"
TS_CONF=/etc/timeshift/timeshift.json
if ! command -v timeshift >/dev/null 2>&1; then
  note "timeshift not installed — skipping"
elif [ ! -f "$TS_CONF" ]; then
  note "writing minimal BTRFS config"
  sudo mkdir -p "$(dirname "$TS_CONF")"
  sudo tee "$TS_CONF" >/dev/null <<'JSON'
{
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "do_first_run" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "false",
  "schedule_hourly" : "false",
  "schedule_boot" : "true",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "3",
  "exclude" : [],
  "exclude-apps" : []
}
JSON
elif sudo grep -q '"btrfs_mode" *: *"true"' "$TS_CONF"; then
  note "already in BTRFS mode"
else
  sudo sed -i 's|"btrfs_mode" *: *"false"|"btrfs_mode" : "true"|' "$TS_CONF"
  note "switched to BTRFS mode"
fi

# 5. Baseline snapshot --------------------------------------------------------
step "Baseline Timeshift snapshot"
if ! command -v timeshift >/dev/null 2>&1; then
  note "timeshift not installed — skipping"
elif sudo timeshift --list 2>/dev/null | grep -q "post-install baseline"; then
  note "already exists"
else
  if sudo timeshift --create --comments "post-install baseline" >/dev/null 2>&1; then
    note "ok"
  else
    note "creation failed — open Timeshift GUI once to finalize device selection"
  fi
fi

# 6. Remaining manual checklist ----------------------------------------------
step "Remaining manual steps"
note "- reboot       — picks up sddm, applies the docker group to your session"
note "- claude       — run from any project dir; first launch opens a browser for OAuth"
note "- blueman      — pair Bluetooth devices"
note "- printers     — http://localhost:631 (CUPS) if needed"

step "Done"
