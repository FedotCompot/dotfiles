-- See https://wiki.hypr.land/Configuring/Basics/Binds/
local progs = require("programs")
local ws    = require("workspaces")

local mainMod = "SUPER"

-- Apps / window management
hl.bind(mainMod .. " + Return",    hl.dsp.exec_cmd(progs.terminal))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(progs.fileManager))
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd(progs.menu))
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())                  -- dwindle
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))            -- dwindle

-- Cycle layouts: dwindle → master → scroller → monocle
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("~/.config/hypr/scripts/cycle-layout.sh"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Cycle windows in monocle layout (layoutmsg required — cyclenext dispatcher skips monocle)
hl.bind(mainMod .. " + ALT + left",  hl.dsp.layout("cycleprev"))
hl.bind(mainMod .. " + ALT + right", hl.dsp.layout("cyclenext"))

-- Move windows with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Move current workspace to the left/right monitor
hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.workspace.move({ monitor = "r" }))

-- Workspace switching — full numbers row: ` 1 2 3 4 5 6 7 8 9 0 - =
local ws_keys = {
    { "dead_grave", ws.ws_terminal },
    { "1",          ws.ws_browser  },
    { "2",          ws.ws_code     },
    { "3",          ws.ws_devops   },
    { "4",          ws.ws_files    },
    { "5",          ws.ws_media    },
    { "6",          ws.ws_chat     },
    { "7",          ws.ws_teams    },
    { "8",          ws.ws_utility  },
    { "9",          ws.ws_settings },
    { "0",          ws.ws_flex1    },
    { "minus",      ws.ws_flex2    },
    { "equal",      ws.ws_flex3    },
}
for _, pair in ipairs(ws_keys) do
    local key, id = pair[1], pair[2]
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = id }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = id }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness (bindel: locked + repeating)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Media controls (bindl: locked only) — requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots
hl.bind("Print",           hl.dsp.exec_cmd("grim - | wl-copy"))                                 -- full screen → clipboard
hl.bind("SHIFT + Print",   hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))                 -- region → clipboard
hl.bind("ALT + SHIFT + S", hl.dsp.exec_cmd("grimblast --freeze save area - | swappy -f -"))    -- region → swappy editor

-- Misc
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen_state({ internal = 1, client = 0, action = "toggle" }))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("helium-browser"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
