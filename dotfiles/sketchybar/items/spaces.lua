local colors = require("colors")

local function mouse_click(env)
	sbar.exec("~/.config/yabai/focus_space.sh " .. env.SID)
end

local function space_selection(env)
	sbar.set(env.NAME, {
		icon = { highlight = env.SELECTED },
		label = { highlight = env.SELECTED },
		background = {
			color = env.SELECTED == "true" and colors.bg1 or colors.bg_inactive,
		},
	})
end

local spaces = {}

local function set_space_label(index)
	sbar.exec([[yabai -m query --spaces label --space ]] .. index .. [[ | jq -r .label]], function(result, exit_code)
		if exit_code == 0 and #result > 1 then
			sbar.set(spaces[index], { icon = { string = result } })
		end
	end)
end

for i = 1, 20 do
	local space = sbar.add("space", {
		associated_space = i,
		icon = {
			string = i,
			padding_left = 7,
			padding_right = 7,
			color = colors.grey,
			highlight_color = colors.white,
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
	set_space_label(i)
end

sbar.add("bracket", spaces, {
	background = { color = colors.bg1, border_color = colors.bg2 },
})

local space_creator = sbar.add("item", {
	padding_left = 10,
	padding_right = 8,
	icon = {
		string = ":add:",
		font = {
			family = "sketchybar-app-font",
			style = "Regular",
			size = 12.0,
		},
	},
	label = { drawing = false },
	associated_display = "active",
})

space_creator:subscribe("mouse.clicked", function(_)
	sbar.exec("~/.config/yabai/new_space.sh")
end)
