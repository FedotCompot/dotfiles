-- Reads ~/.config/hypr/monitors.conf (written in hyprlang by hyprmoncfg) and
-- applies each block/line via the Lua hl.* API. monitors.conf stays under
-- hyprmoncfg's control — do not hand-edit it.

local home = os.getenv("HOME") or ("/home/" .. (os.getenv("USER") or ""))
local xdg  = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local conf_path = xdg .. "/hypr/monitors.conf"

-- hl.MonitorSpec field types we care about (from /usr/share/hypr/stubs/hl.meta.lua):
--   output/mode/position/scale/transform/cm/icc/mirror/sdr_eotf  -> string
--   disabled                                                     -> boolean
--   sdr_min_luminance/sdr_max_luminance/sdrbrightness/...         -> number
local STRING_KEYS = {
    output = true, mode = true, position = true, scale = true, transform = true,
    cm = true, icc = true, mirror = true, sdr_eotf = true,
}
local BOOLEAN_KEYS = { disabled = true }

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function to_bool(v)
    return v == "1" or v == "true" or v == "yes" or v == "on"
end

local function coerce_monitor_value(key, value)
    value = trim(value)
    if BOOLEAN_KEYS[key] then return to_bool(value) end
    if STRING_KEYS[key]  then return value end
    local n = tonumber(value)
    if n ~= nil then return n end
    return value
end

-- Parse `workspace = <id>, key:value, key:value` payload (the part after `=`).
-- Values like `monitor:desc:Lenovo X` have nested colons; we split only on the
-- first one so `desc:Lenovo X` stays intact as the value.
local function parse_workspace_rule(payload)
    local rule  = {}
    local comma = payload:find(",")
    if not comma then
        rule.workspace = trim(payload)
        return rule
    end
    rule.workspace = trim(payload:sub(1, comma - 1))
    for raw_chunk in payload:sub(comma + 1):gmatch("[^,]+") do
        local chunk = trim(raw_chunk)
        local c = chunk:find(":")
        if c then
            local k = trim(chunk:sub(1, c - 1))
            local v = trim(chunk:sub(c + 1))
            if     v == "true"  then v = true
            elseif v == "false" then v = false
            end
            rule[k] = v
        end
    end
    return rule
end

local f = io.open(conf_path, "r")
if f then
    local in_block, spec = false, nil
    for raw in f:lines() do
        local line = trim(raw)
        if line == "" or line:sub(1, 1) == "#" then
            -- comment or blank
        elseif line:match("^monitorv?2?%s*{") then
            in_block, spec = true, {}
        elseif in_block and line:sub(1, 1) == "}" then
            if spec and spec.output then hl.monitor(spec) end
            in_block, spec = false, nil
        elseif in_block then
            local k, v = line:match("^([%w_]+)%s*=%s*(.*)$")
            if k then spec[k] = coerce_monitor_value(k, v) end
        elseif line:match("^workspace%s*=") then
            local payload = line:match("^workspace%s*=%s*(.*)$")
            if payload then hl.workspace_rule(parse_workspace_rule(payload)) end
        end
    end
    f:close()
end

-- Fallback for any unspecified monitor (was `monitor=,preferred,auto,auto`)
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
