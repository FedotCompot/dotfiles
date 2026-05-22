local M = {}

M.terminal         = "alacritty"
M.fileManager      = "thunar"
M.menu             = "hyprlauncher"
M.browser          = "helium-browser"
-- Helium profiles: each gets its own --user-data-dir so they run as
-- separate processes (Chromium reuses the running instance otherwise,
-- which makes --class on later invocations a no-op).
M.browser_personal = "helium-browser --class=helium-personal --user-data-dir=$HOME/.config/net.imput.helium-personal"
M.browser_work     = "helium-browser --class=helium-work     --user-data-dir=$HOME/.config/net.imput.helium-work"
M.editor           = "code"
M.devopsApp        = "freelens"
M.media            = "spotify"
M.chat             = "discord"
M.teamsApp         = "ferdium"
M.utilApp          = "obsidian"
M.sysApp           = "pavucontrol"

return M
