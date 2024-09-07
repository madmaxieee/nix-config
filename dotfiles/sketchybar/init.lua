---@diagnostic disable-next-line: lowercase-global
sbar = require("sketchybar")

sbar.begin_config()
require("plugins.media")
sbar.hotload(true)
sbar.end_config()

sbar.event_loop()
