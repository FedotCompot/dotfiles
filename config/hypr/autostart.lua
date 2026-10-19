-- Autostart necessary processes (notifications daemons, status bars, etc.)
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    -- user units, so systemd owns respawns and D-Bus activation
    hl.exec_cmd("systemctl --user import-environment GTK_THEME GTK_IM_MODULE XCURSOR_SIZE HYPRCURSOR_SIZE && systemctl --user start waybar.service swaync.service")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("udiskie &")
    hl.exec_cmd("wl-paste --watch cliphist store &")  -- clipboard history daemon
end)
