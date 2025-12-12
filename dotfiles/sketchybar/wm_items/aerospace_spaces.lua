local sbar = require "sketchybar"
local colors = require "colors"
local icon_map = require "icon_map"

local M = {}

local spaces = {}
local spaces_exist = {}
local space_apps = {}

local NUM_SPACES = 10

local function rerender_space_button(id)
    local label_content = ""
    if space_apps[id] then
        for _, val in ipairs(space_apps[id]) do
            label_content = label_content .. (icon_map[val] and icon_map[val] or ":default:") .. " "
        end
    end
    sbar.set(spaces[id], {
        icon = { string = id },
        label = { string = label_content, drawing = label_content ~= "" },
        drawing = spaces_exist[id] == true,
    })
end

local function rerender_all_spaces()
    for id, _ in pairs(spaces) do
        rerender_space_button(id)
    end
end

local function update_spaces(cb)
    sbar.exec("aerospace list-workspaces --all", function(result, exit_code)
        if exit_code == 0 and #result > 1 then
            spaces_exist = {}
            for line in string.gmatch(result, "([^\n]+)") do
                spaces_exist[line] = true
            end
            cb()
        end
    end)
end

function M.setup(opts)
    opts = opts or {}

    local from = 1
    local to = NUM_SPACES
    local step = 1
    if opts.position == "right" then
        from = NUM_SPACES
        to = 1
        step = -1
    end

    for i = from, to, step do
        local id = tostring(i)
        local space = sbar.add("item", ("space.%s"):format(id), {
            position = opts.position,
            icon = {
                string = id,
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
                    size = 12,
                },
                y_offset = -1.5,
            },
            background = {
                color = colors.bg_inactive,
                corner_radius = 5,
                height = 22,
            },
        })
        spaces[id] = space
        space:subscribe("aerospace_workspace_change", function(env)
            sbar.set(spaces[id], {
                icon = { highlight = env.FOCUSED_WORKSPACE == id },
                label = { highlight = env.FOCUSED_WORKSPACE == id },
                background = {
                    color = env.FOCUSED_WORKSPACE == id and colors.bg1 or colors.bg_inactive,
                },
            })
        end)
        space:subscribe("mouse.clicked", function()
            sbar.exec(("aerospace workspace %s"):format(id))
            sbar.set(spaces[id], {
                icon = { highlight = "true" },
                label = { highlight = "true" },
                background = { color = colors.bg1 },
            })
        end)
    end

    local space_update_listener = sbar.add("item", "space_update_listener", {
        drawing = false,
        updates = true,
    })
    ---@diagnostic disable-next-line: unused-local
    space_update_listener:subscribe("aerospace_workspace_change", function(env)
        update_spaces(rerender_all_spaces)
    end)
    -- TODO: trigger event using hammerspoon app watcher
    space_update_listener:subscribe("aerospace_update_space_apps", function(env)
        local id = env.SPACE
        space_apps[id] = {}
        for _, app in ipairs(env.APPS) do
            if env.VISIBLE[app] then
                table.insert(space_apps[id], app)
            end
        end
        rerender_space_button(id)
    end)

    update_spaces(rerender_all_spaces)
    sbar.exec "~/.config/sketchybar/wm_items/aerospace_update_space_apps_all.sh"

    -- local space_apps_refresh_listener = sbar.add("item", "space_apps_refresh_listener", {
    --     drawing = false,
    --     updates = true,
    -- })
    -- space_apps_refresh_listener:subscribe("space_apps_refresh", function(_)
    --     for i = 1, NUM_SPACES do
    --         update_space_apps(i)
    --     end
    -- end)
end

return M
