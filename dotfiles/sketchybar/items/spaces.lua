local colors = require "colors"
local icon_map = require "icon_map"

local spaces = {}
local space_labels = {}
local space_apps = {}

local NUM_SPACES = 15

local function rerender_space_button(index)
    local icon_content = tostring(index)
    if space_labels[index] and space_labels[index] ~= "" then
        icon_content = icon_content .. " " .. space_labels[index]
    end
    local label_content = ""
    if space_apps[index] then
        for _, val in ipairs(space_apps[index]) do
            label_content = label_content .. (icon_map[val] and icon_map[val] or ":default:") .. " "
        end
    end
    sbar.set(spaces[index], {
        icon = { string = icon_content },
        label = { string = label_content, drawing = label_content ~= "" },
    })
end

local function set_space_label(index)
    local cmd = table.concat({
        [[yabai -m query --spaces label --space ]],
        index,
        [[ | jq -r .label]],
    }, "")
    sbar.exec(cmd, function(result, exit_code)
        if exit_code == 0 and #result > 1 then
            space_labels[index] = result
            rerender_space_button(index)
        end
    end)
end

local function update_space_apps(index)
    local cmd = table.concat({
        [[yabai -m query --windows app,subrole,is-hidden --space ]],
        index,
        [[ | jq -r  '.[] | select(.subrole == "AXStandardWindow" and ."is-hidden" == false) | .app']],
    }, "")
    sbar.exec(cmd, function(result, exit_code)
        if exit_code == 0 then
            space_apps[index] = {}
            for app in result:gmatch "[^\n]+" do
                table.insert(space_apps[index], app)
            end
            rerender_space_button(index)
        end
    end)
end

local function on_mouse_click(env)
    sbar.exec("~/.config/yabai/focus_space.sh " .. env.SID)
    sbar.set(spaces[tonumber(env.SID)], {
        icon = { highlight = "true" },
        label = { highlight = "true" },
        background = { color = colors.bg1 },
    })
end

local function on_space_change(env)
    sbar.set(env.NAME, {
        icon = { highlight = env.SELECTED },
        label = { highlight = env.SELECTED },
        background = {
            color = env.SELECTED == "true" and colors.bg1 or colors.bg_inactive,
        },
    })
end

local function on_space_windows_change(env)
    update_space_apps(tonumber(env.SID))
end

for i = 1, NUM_SPACES do
    local space = sbar.add("space", {
        associated_space = i,
        icon = {
            string = i,
            padding_left = 7,
            padding_right = 7,
            color = colors.white_inactive,
            highlight_color = colors.white,
        },
        label = {
            drawing = false,
            color = colors.white_inactive,
            highlight_color = colors.white,
            font = {
                family = "sketchybar-app-font",
                style = "Regular",
                size = 12.0,
            },
            y_offset = -1.5,
        },
        background = {
            color = colors.bg1,
            corner_radius = 5,
            height = 24,
        },
    })
    spaces[i] = space.name
    space:subscribe("space_change", on_space_change)
    space:subscribe("space_windows_change", on_space_windows_change)
    space:subscribe("mouse.clicked", on_mouse_click)
    set_space_label(i)
    update_space_apps(i)
end

sbar.add("bracket", spaces, {
    background = { color = colors.bg1, border_color = colors.bg2 },
})

-- triggered from yabai signal
sbar.add("event", "space_apps_refresh")
local space_apps_refresh_listener = sbar.add("item", "space_apps_refresh_listener", {
    icon = { drawing = false },
    label = { drawing = false },
    padding_left = 0,
    padding_right = 0,
})
space_apps_refresh_listener:subscribe("space_apps_refresh", function(_)
    for i = 1, NUM_SPACES do
        update_space_apps(i)
    end
end)

-- space creator
local space_creator = sbar.add("item", {
    padding_left = 10,
    padding_right = 8,
    icon = {
        string = ":add:",
        font = "sketchybar-app-font:Regular:12.0",
    },
    label = { drawing = false },
    associated_display = "active",
})

space_creator:subscribe("mouse.clicked", function(_)
    sbar.exec "~/.config/yabai/new_space.sh"
end)
