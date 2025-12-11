---@class WM
---@field setup function

local has_yabai = os.execute "which yabai"

if has_yabai then
    return require "wm_items.yabai"
end

local has_aerospace = os.execute "which aerospace"

if has_aerospace then
    return require "wm_items.aerospace"
end

error "No supported window manager found (yabai or aerospace)"
