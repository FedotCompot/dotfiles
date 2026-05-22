-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
local ws = require("workspaces")

-- Terminal opacity
hl.window_rule({
    name  = "terminal-opacity",
    match = { class = "Alacritty" },
    opacity = "0.90 0.70",
})

-- Ignore maximize requests from all apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Hyprland-run helper
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- App → workspace assignment
-- workspace IDs: 1=terminal ` | 2=browser 1 | 3=code 2 | 4=devops 3 | 5=files 4
--                6=media 5   | 7=chat 6    | 8=teams 7 | 9=utility 8 | 10=settings 9

hl.window_rule({ name = "ws-terminal",         match = { class = "Alacritty" },                                                                                                       workspace = ws.ws_terminal })
hl.window_rule({ name = "ws-browser-work",     match = { class = "^(helium-work|helium|[Cc]hromium|firefox|brave-browser)$" },                                                        workspace = ws.ws_browser })
hl.window_rule({ name = "ws-browser-personal", match = { class = "^(helium-personal)$" },                                                                                             workspace = ws.ws_flex1 })
hl.window_rule({ name = "ws-code",             match = { class = "^(code-url-handler|[Cc]ode|[Cc]odium|VSCodium)$" },                                                                 workspace = ws.ws_code     .. " silent" })
hl.window_rule({ name = "ws-devops",           match = { class = "^(Freelens)$" },                                                                                                    workspace = ws.ws_devops })
hl.window_rule({ name = "ws-devops-navicat",   match = { title = "^Navicat Premium.*$" },                                                                                             workspace = ws.ws_devops   .. " silent" })
hl.window_rule({ name = "ws-files",            match = { class = "^.*(dolphin|[Tt]hunar|[Nn]autilus|[Nn]emo)$" },                                                                     workspace = ws.ws_files })
hl.window_rule({ name = "ws-media",            match = { class = "^([Ss]potify|vlc|mpv)$" },                                                                                          workspace = ws.ws_media    .. " silent" })
hl.window_rule({ name = "ws-chat",             match = { class = "^([Dd]iscord|vesktop|.*ayugram.*|TelegramDesktop|telegram-desktop|org\\.telegram\\.desktop)$" },                     workspace = ws.ws_chat     .. " silent" })
hl.window_rule({ name = "ws-teams",            match = { class = "^(Ferdium)$" },                                                                                                     workspace = ws.ws_teams    .. " silent" })
hl.window_rule({ name = "ws-utility",          match = { class = "^([Oo]bsidian|zathura|evince)$" },                                                                                  workspace = ws.ws_utility  .. " silent" })
hl.window_rule({ name = "ws-settings",         match = { class = "^(org\\.pulseaudio\\.pavucontrol|blueman-manager|gnome-control-center|nm-connection-editor)$" },                    workspace = ws.ws_settings })
