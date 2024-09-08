local colors = require("colors")

local function mouse_click(env)
	sbar.exec("~/.config/yabai/focus_space.sh " .. env.SID)
end

local function space_selection(env)
	local color = env.SELECTED == "true" and colors.white or colors.bg2

	sbar.set(env.NAME, {
		icon = { highlight = env.SELECTED },
		label = { highlight = env.SELECTED },
		background = { border_color = color },
	})
end

local spaces = {}
for i = 1, 10, 1 do
	local space = sbar.add("space", {
		associated_space = i,
		icon = {
			string = i,
			padding_left = 7,
			padding_right = 7,
			color = colors.white,
			highlight_color = colors.red,
		},
		label = {
			drawing = false,
		},
		background = {
			color = colors.bg1,
			corner_radius = 5,
			height = 26,
		},
	})
	spaces[i] = space.name
	space:subscribe("space_change", space_selection)
	space:subscribe("mouse.clicked", mouse_click)
end

sbar.add("bracket", spaces, {
	background = { color = colors.bg1, border_color = colors.bg2 },
})

local space_creator = sbar.add("item", {
	padding_left = 10,
	padding_right = 8,
	icon = {
		string = "+",
		font = {
			style = "Heavy",
			size = 16.0,
		},
	},
	label = { drawing = false },
	associated_display = "active",
})

space_creator:subscribe("mouse.clicked", function(_)
	sbar.exec("yabai -m space --create")
end)
