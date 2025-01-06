local colors = require "colors"

-- Equivalent to the --bar domain
sbar.bar {
    position = "bottom",
    height = 28,
    blur_radius = 20,
    color = colors.bar.bg,
    sticky = true,
}
