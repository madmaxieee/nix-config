---@diagnostic disable: undefined-global

local function formatBytes(bytes)
	if bytes == 0 then
		return "0b"
	end

	local k = 1024
	local dm = 1
	local sizes = { "b", "kb", "mb", "gb", "tb", "pb", "eb", "zb", "yb" }

	local i = math.floor(math.log(bytes) / math.log(k))

	local value = bytes / (k ^ i)
	if value >= 100 then
		dm = 0
	end
	local formattedValue = string.format("%." .. dm .. "f", value)

	return formattedValue .. " " .. sizes[i + 1]
end

local colors = require("colors")

local netstat_up = sbar.add("item", {
	position = "right",
	width = 72,
	icon = { drawing = false },
	label = { color = colors.blue },
})
sbar.add("item", {
	position = "right",
	icon = {
		string = "",
		font = "JetBrainsMono Nerd Font:Regular:18.0",
		color = colors.blue,
	},
	label = { drawing = false },
})
local netstat_down = sbar.add("item", {
	position = "right",
	width = 72,
	icon = { drawing = false },
	label = { color = colors.red },
})
sbar.add("item", {
	position = "right",
	icon = {
		string = "",
		font = "JetBrainsMono Nerd Font:Regular:18.0",
		color = colors.red,
	},
	label = { drawing = false },
})

sbar.add("event", "netstat_update")

sbar.exec("~/.config/sketchybar/items/netstat.sh")

netstat_up:subscribe("netstat_update", function(env)
	load("NETSTAT_SPEED=" .. env.INFO)()
	local download = formatBytes(NETSTAT_SPEED.download)
	local upload = formatBytes(NETSTAT_SPEED.upload)
	netstat_up:set({
		label = { string = upload },
	})
	netstat_down:set({
		label = { string = download },
	})
end)
