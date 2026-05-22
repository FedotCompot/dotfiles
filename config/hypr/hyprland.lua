-- #######################################################################################
-- HYPRLAND CONFIG (Lua, for Hyprland 0.55+)
-- Refer to https://wiki.hypr.land/Configuring/ for documentation.
-- #######################################################################################

-- Environment variables (set early so launched apps inherit them)
-- Forza le app Electron e Chromium a usare Wayland nativo
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("NIXOS_OZONE_WL",               "1")
hl.env("GTK_IM_MODULE",                "ibus")
-- Forza le app GTK a usare la variante scura
hl.env("GTK_THEME",                    "adw-gtk3-dark")
-- Forza il tema scuro sulle app Qt (quelle in stile KDE)
hl.env("QT_QPA_PLATFORMTHEME",         "qt6ct")
hl.env("QT_STYLE_OVERRIDE",            "kvantum")
-- Cursor sizing
hl.env("XCURSOR_SIZE",                 "24")
hl.env("HYPRCURSOR_SIZE",              "24")

-- Module requires — each is its own Lua scope, so a runtime error in one
-- file does not abort execution of the others.
require("monitors")
require("look_and_feel")
require("input")
require("workspaces")
require("window_rules")
require("binds")
require("autostart")
