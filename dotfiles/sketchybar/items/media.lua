local colors = require("colors")
local app_icons = require("icon_map")
app_icons.default = ":default:"

local whitelist = {
	["Spotify"] = colors.green,
	["Podcasts"] = colors.magenta,
}

local current_app = nil

local media = sbar.add("item", "media", {
	icon = {
		font = "sketchybar-app-font:Regular:12.0",
		padding_left = 12,
		padding_right = 12,
	},
	label = {
		font = "JetBrainsMono Nerd Font:Regular:14.0",
		padding_right = 12,
	},
	position = "center",
	updates = true,
})

media:subscribe("mouse.clicked", function(_)
	if current_app == "Spotify" then
		sbar.exec([[hs -c 'hs.spotify.playpause()']])
	elseif current_app == "Podcasts" then
		sbar.exec([[hs -c 'hs.eventtap.keyStroke({}, "space", 0, hs.application.find("Podcasts"))']])
	else
		sbar.exec([[hs -c 'hs.eventtap.event.newSystemKeyEvent("PLAY", true):post()']])
	end
end)

media:subscribe("media_change", function(env)
	local app_color = whitelist[env.INFO.app]
	if app_color ~= nil then
		current_app = env.INFO.app
		local lookup = app_icons[env.INFO.app]
		local icon = ((lookup == nil) and app_icons["default"] or lookup)

		local playback_icon = ((env.INFO.state == "playing") and "" or "")

		local artist = (env.INFO.artist ~= "" and env.INFO.artist) or "Unknown Artist"
		local title = (env.INFO.title ~= "" and env.INFO.title) or "Unknown Title"
		local label = playback_icon .. "  " .. artist .. ": " .. title

		sbar.animate("tanh", 10, function()
			media:set({
				icon = { string = icon, color = app_color },
				label = { string = label },
			})
		end)
	end
end)
