-- Autostart necessary processes (notifications daemons, status bars, etc.)
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    -- waybar runs as a user unit so systemd and its watchdog can respawn it
    hl.exec_cmd("systemctl --user import-environment GTK_THEME GTK_IM_MODULE XCURSOR_SIZE HYPRCURSOR_SIZE && systemctl --user start waybar.service")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("udiskie &")
    hl.exec_cmd("wl-paste --watch cliphist store &")  -- clipboard history daemon
end)
