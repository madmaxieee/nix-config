local icon_map = require("icon_map")
local front_app = sbar.add("item", { icon = {
	font = "sketchybar-app-font:Regular:16.0",
	drawing = false,
} })

front_app:subscribe("front_app_switched", function(env)
	local icon = icon_map[env.INFO]
	front_app:set({
		label = { string = env.INFO },
		icon = {
			drawing = icon ~= nil,
			string = icon,
		},
	})
end)
