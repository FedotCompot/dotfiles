local progs = require("programs")
local M = {}

-- Monitor names — keep workspace assignments below readable and portable
M.monitor_left   = "DP-4"
M.monitor_center = "HDMI-A-1"
M.monitor_right  = "DP-3"

-- Numbers row layout (left → right): ` 1 2 3 4 5 6 7 8 9 0 - =
-- Workspace IDs match physical keyboard position so waybar order is consistent
M.ws_terminal = "1"   -- ` — terminal
M.ws_browser  = "2"   -- 1 — browser
M.ws_code     = "3"   -- 2 — code editor
M.ws_devops   = "4"   -- 3 — devops
M.ws_files    = "5"   -- 4 — file manager
M.ws_media    = "6"   -- 5 — multimedia
M.ws_chat     = "7"   -- 6 — discord / telegram
M.ws_teams    = "8"   -- 7 — teams (ferdium)
M.ws_utility  = "9"   -- 8 — utility
M.ws_settings = "10"  -- 9 — system settings
M.ws_flex1    = "11"  -- 0 — flexible
M.ws_flex2    = "12"  -- - — flexible
M.ws_flex3    = "13"  -- = — flexible

-- Open default app when a workspace is visited for the first time
hl.workspace_rule({ workspace = M.ws_terminal, monitor = M.monitor_center, on_created_empty = "alacritty" })
hl.workspace_rule({ workspace = M.ws_browser,  monitor = M.monitor_left,   on_created_empty = progs.browser_work })
hl.workspace_rule({ workspace = M.ws_flex1,    monitor = M.monitor_left,   on_created_empty = progs.browser_personal })
hl.workspace_rule({ workspace = M.ws_code,     monitor = M.monitor_center, on_created_empty = "~/.config/hypr/scripts/code-workspace.sh" })
hl.workspace_rule({ workspace = M.ws_devops,   monitor = M.monitor_center, on_created_empty = "freelens" })
hl.workspace_rule({ workspace = M.ws_files,    monitor = M.monitor_center, on_created_empty = "thunar" })
hl.workspace_rule({ workspace = M.ws_media,    monitor = M.monitor_right,  on_created_empty = "spotify" })
hl.workspace_rule({ workspace = M.ws_chat,     monitor = M.monitor_right,  on_created_empty = "vesktop" })
hl.workspace_rule({ workspace = M.ws_teams,    monitor = M.monitor_right,  on_created_empty = "ferdium" })
hl.workspace_rule({ workspace = M.ws_utility,  monitor = M.monitor_right,  on_created_empty = "obsidian" })
hl.workspace_rule({ workspace = M.ws_settings, monitor = M.monitor_right,  on_created_empty = "pavucontrol" })

return M
