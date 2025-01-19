local M = {}

local sbar = require "sketchybar"
local icon_map = require "icon_map"

function M.setup(opts)
    opts = opts or {}

    local front_app = sbar.add("item", {
        position = opts.position,
        icon = {
            font = {
                family = "sketchybar-app-font",
                style = "Regular",
                size = 14,
            },
            drawing = false,
        },
    })
    M.item = front_app

    front_app:subscribe("front_app_switched", function(env)
        local icon = icon_map[env.INFO]
        front_app:set {
            label = { string = env.INFO },
            icon = {
                drawing = icon ~= nil,
                string = icon,
            },
        }
    end)
end

return M
