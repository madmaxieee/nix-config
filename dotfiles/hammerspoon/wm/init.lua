---@class WM
---@field setup function

local _, has_yabai = hs.execute("which yabai", true)

if has_yabai then
    local wm = require("wm.yabai")
    wm.setup()
    return wm
end

local _, has_aerospace = hs.execute("which aerospace", true)

if has_aerospace then
    local wm = require("wm.aerospace")
    wm.setup()
    return wm
end

hs.alert.show("No supported window manager found (yabai or aerospace)")
