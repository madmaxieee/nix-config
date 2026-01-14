local sbar = require("sketchybar")

local M = {}

function M.setup(opts)
    opts = opts or {}

    local space_creator = sbar.add("item", {
        position = opts.position,
        padding_left = 10,
        padding_right = 8,
        icon = {
            string = ":add:",
            font = {
                family = "sketchybar-app-font",
                style = "Regular",
                size = 10,
            },
        },
        label = { drawing = false },
        associated_display = "active",
    })
    M.item = space_creator

    space_creator:subscribe("mouse.clicked", function(_)
        sbar.exec("~/.config/yabai/new_space.sh")
    end)
end

return M
