-- Helium picture-in-picture: float, pin, remember size and position
local state_file = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state") .. "/hypr/pip-geometry"

hl.window_rule({
    name              = "float-helium-pip",
    match             = { class = "^$", title = "^Picture in picture$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    rounding          = 0,
})

local function is_pip(w)
    return w and w.class == "" and w.title == "Picture in picture"
end

local function load_geometry()
    local f = io.open(state_file, "r")
    if not f then return nil end
    local mon, x, y, w, h = f:read("*l"):match("^(%S+) (%-?%d+) (%-?%d+) (%d+) (%d+)$")
    f:close()
    if not mon then return nil end
    return { monitor = mon, x = tonumber(x), y = tonumber(y), w = tonumber(w), h = tonumber(h) }
end

local function save_geometry(g)
    os.execute("mkdir -p '" .. state_file:match("^(.*)/") .. "'")
    local f = io.open(state_file, "w")
    if not f then return end
    f:write(string.format("%s %d %d %d %d\n", g.monitor, g.x, g.y, g.w, g.h))
    f:close()
end

-- Geometry at close is bogus, so track it while open
local last = {}
hl.timer(function()
    for _, w in ipairs(hl.get_windows()) do
        if is_pip(w) and w.monitor then
            last[w.address] = {
                monitor = w.monitor.name,
                x = w.at.x - w.monitor.x, y = w.at.y - w.monitor.y,
                w = w.size.x, h = w.size.y,
            }
        end
    end
end, { timeout = 1000, type = "repeat" })

hl.on("window.close", function(w)
    if not is_pip(w) or not last[w.address] then return end
    save_geometry(last[w.address])
    last[w.address] = nil
end)

-- Restore the saved area at the video's aspect, anchored to the saved nearest corner
hl.on("window.open", function(w)
    if not is_pip(w) then return end
    local g = load_geometry()
    if not g or w.size.x == 0 or w.size.y == 0 then return end
    local mon = hl.get_monitor(g.monitor) or w.monitor
    if not mon then return end

    local scale = math.sqrt(g.w * g.h / (w.size.x * w.size.y))
    local nw, nh = math.floor(w.size.x * scale + 0.5), math.floor(w.size.y * scale + 0.5)
    local x = (g.x + g.w / 2 > mon.width / 2) and (g.x + g.w - nw) or g.x
    local y = (g.y + g.h / 2 > mon.height / 2) and (g.y + g.h - nh) or g.y
    x = math.max(0, math.min(x, mon.width - nw))
    y = math.max(0, math.min(y, mon.height - nh))

    local target = "address:" .. w.address
    hl.dispatch(hl.dsp.window.resize({ x = nw, y = nh, window = target }))
    hl.dispatch(hl.dsp.window.move({ x = mon.x + x, y = mon.y + y, window = target }))
end)
