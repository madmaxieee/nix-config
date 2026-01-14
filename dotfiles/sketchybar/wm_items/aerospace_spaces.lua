local sbar = require("sketchybar")
local colors = require("colors")
local icon_map = require("icon_map")

local M = {}

local spaces = {}
local spaces_exist = {}
local space_apps = {}

local separators = {}

local NUM_SPACES = 10

local function rerender_space_button(id)
    local label_content = ""
    if space_apps[id] then
        for _, val in ipairs(space_apps[id]) do
            label_content = label_content
                .. (icon_map[val] and icon_map[val] or ":default:")
                .. " "
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

local function update_spaces_exist(cb)
    sbar.exec("aerospace list-workspaces --all", function(result, exit_code)
        if exit_code == 0 and #result > 1 then
            for k in pairs(spaces_exist) do
                spaces_exist[k] = false
            end
            for line in string.gmatch(result, "([^\n]+)") do
                spaces_exist[line] = true
            end
            cb()
        end
    end)
end

local function move_item_after(item, ref_item)
    sbar.exec(
        ([[sketchybar --move '%s' after '%s']]):format(item.name, ref_item.name)
    )
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
        space:subscribe("mouse.clicked", function(env)
            if env.BUTTON == "left" then
                sbar.exec(("aerospace workspace %s"):format(id))
                sbar.set(spaces[id], {
                    icon = { highlight = "true" },
                    label = { highlight = "true" },
                    background = { color = colors.bg1 },
                })
            elseif env.BUTTON == "right" then
                sbar.exec(
                    ("aerospace move-workspace-to-monitor --workspace '%s' --wrap-around next"):format(
                        id
                    ),
                    function()
                        sbar.exec("~/.config/sketchybar/wm_items/aerospace_update_monitor_workspace.sh")
                    end
                )
            end
        end)
    end

    for i = 1, 3 do
        -- don't draw anything, just add extra padding
        local sep = sbar.add("item", ("sep.%d"):format(i), {
            position = opts.position,
            icon = { drawing = false },
            label = { drawing = false },
            drawing = false,
        })
        separators[i] = sep
    end

    local space_update_listener = sbar.add("item", "space_update_listener", {
        drawing = false,
        updates = true,
    })

    space_update_listener:subscribe("aerospace_workspace_change", function(env)
        for id, _ in pairs(spaces) do
            sbar.set(spaces[id], {
                icon = { highlight = env.FOCUSED_WORKSPACE == id },
                label = { highlight = env.FOCUSED_WORKSPACE == id },
                background = {
                    color = env.FOCUSED_WORKSPACE == id and colors.bg1
                        or colors.bg_inactive,
                },
            })
        end
        update_spaces_exist(rerender_all_spaces)
    end)

    space_update_listener:subscribe("aerospace_update_space_apps", function(env)
        local id = env.SPACE
        space_apps[id] = {}
        if #env.APPS > 0 then
            spaces_exist[id] = true
        end
        for _, app in ipairs(env.APPS) do
            if env.VISIBLE[app] then
                table.insert(space_apps[id], app)
            end
        end
        rerender_space_button(id)
    end)

    space_update_listener:subscribe(
        "aerospace_update_monitor_spaces",
        function(env)
            local data = env.DATA
            for _, sep in ipairs(separators) do
                sbar.set(sep, { drawing = false })
            end
            for monitor_id, space_ids in ipairs(data) do
                if #space_ids > 0 then
                    local ref_space_id = space_ids[1]
                    if monitor_id > 1 then
                        move_item_after(
                            spaces[ref_space_id],
                            separators[monitor_id - 1]
                        )
                        sbar.set(separators[monitor_id - 1], { drawing = true })
                    end
                    for i = 2, #space_ids do
                        move_item_after(
                            spaces[space_ids[i]],
                            spaces[ref_space_id]
                        )
                        ref_space_id = space_ids[i]
                    end
                    move_item_after(
                        separators[monitor_id],
                        spaces[ref_space_id]
                    )
                end
            end
        end
    )

    update_spaces_exist(rerender_all_spaces)
    sbar.exec("~/.config/sketchybar/wm_items/aerospace_update_space_apps_all.sh")
    sbar.exec("~/.config/sketchybar/wm_items/aerospace_update_monitor_workspace.sh")
end

return M
