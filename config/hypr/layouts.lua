-- See https://wiki.hypr.land/Configuring/Layouts/Custom-Layouts/
-- Equal-width columns side by side (vim's :vsplit)
hl.layout.register("vertical", { recalculate = function(ctx)
    local n = #ctx.targets
    for i, target in ipairs(ctx.targets) do target:place(ctx:column(i, n)) end
end })

-- Equal-height rows stacked top to bottom (vim's :split)
hl.layout.register("horizontal", { recalculate = function(ctx)
    local n = #ctx.targets
    for i, target in ipairs(ctx.targets) do target:place(ctx:row(i, n)) end
end })

-- Discord left, Telegram right at fixed widths; anything else falls back to columns
local telegram_share = 720 / 2550

local function chat_app(target)
    local class = target.window and target.window.class:lower() or ""
    if class == "discord" or class == "vesktop" then return "discord" end
    if class:find("telegram", 1, true) or class:find("ayugram", 1, true) then return "telegram" end
end

hl.layout.register("chat", { recalculate = function(ctx)
    local apps = {}
    for _, target in ipairs(ctx.targets) do
        local app = chat_app(target)
        if app then apps[app] = target end
    end
    if #ctx.targets ~= 2 or not (apps.discord and apps.telegram) then
        for i, target in ipairs(ctx.targets) do target:place(ctx:column(i, #ctx.targets)) end
        return
    end
    apps.discord:place(ctx:split(ctx.area, "left", 1 - telegram_share))
    apps.telegram:place(ctx:split(ctx.area, "right", telegram_share))
end })
