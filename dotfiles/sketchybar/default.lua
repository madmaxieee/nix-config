local sbar = require "sketchybar"
local colors = require "colors"

-- Equivalent to the --default domain
sbar.default {
    updates = "when_shown",
    icon = {
        font = {
            family = "JetBrainsMono Nerd Font",
            style = "Semibold",
            size = 12,
        },
        color = colors.white,
        padding_left = 4,
        padding_right = 4,
    },
    label = {
        font = {
            family = "JetBrainsMono Nerd Font",
            style = "Semibold",
            size = 12,
        },
        color = colors.white,
        padding_left = 4,
        padding_right = 4,
    },
    padding_left = 5,
    padding_right = 5,
}
