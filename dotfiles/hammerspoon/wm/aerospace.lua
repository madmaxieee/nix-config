local M = { name = "aerospace" }

local leader_mode = require "leader_mode"
local leader_bind = leader_mode.bind

local function aerospace_cmd(cmd)
    return ("PATH=%s aerospace %s"):format(PATH, cmd)
end

local function aerospace(args)
    return hs.execute(aerospace_cmd(args))
end

function M.setup()
    -- toggle window floating
    leader_bind("", "f", function()
        aerospace "layout floating tiling"
    end)

    -- zoom in/out a window (toggle accordion layout)
    leader_bind("", "z", function()
        aerospace "layout tiles accordion"
    end)

    leader_bind("", "r", function()
        aerospace "workspace-back-and-forth"
    end)

    leader_bind("", "l", function()
        hs.execute(table.concat({
            aerospace_cmd "list-workspaces --all",
            "|",
            "grep -v '^0$'",
            "|",
            aerospace_cmd "workspace --wrap-around --stdin next",
        }, " "))
    end, { repeatable = true })
    leader_bind("", "h", function()
        hs.execute(table.concat({
            aerospace_cmd "list-workspaces --all",
            "|",
            "grep -v '^0$'",
            "|",
            aerospace_cmd "workspace --wrap-around --stdin prev",
        }, " "))
    end, { repeatable = true })

    for i = 1, 9 do
        leader_bind("", tostring(i), function()
            aerospace("workspace " .. tostring(i))
        end)
    end
    leader_bind("", "0", function()
        aerospace "workspace 10"
    end)
end

-- TODO: store floating window id somewhere
function M.is_managed(win_id)
    local win = hs.window.get(win_id)
    if not win then
        return true
    end

    local app = win:application()
    if not app then
        return true
    end
    ---@cast app hs.application

    local app_name = app:name()
    if app_name == "Google Chat" or app_name == "T3 Chat" then
        return false
    end

    local bid = app:bundleID()
    if bid == "com.apple.finder" or bid == "com.apple.systempreferences" then
        return false
    end

    local win_title = win:title()
    if app_name == "kitty" and win_title == "script kitty" then
        return false
    end

    return true
end

---@param window hs.window
function M.move_window_to_current_space(window)
    hs.execute([[PATH=]] .. PATH .. [[ ~/.config/aerospace/move_window_to_current_workspace.sh ]] .. window:id())
end

---@param app hs.application
function M.hide_app(app)
    aerospace(("move-node-to-workspace --window-id %d 0"):format(app:mainWindow():id()))
end

function TryResizeScriptKitty(win_id)
    local win = hs.window.get(win_id)
    if not win then
        return
    end
    if win:title() ~= "script kitty" then
        return
    end
    local app = win:application()
    if not app then
        return
    end
    if app:name() ~= "kitty" then
        return
    end
    -- do resize
    local new_geometry = hs.geometry.size(900, 600)
    if win:size():equals(new_geometry) then
        win:centerOnScreen()
        return
    end
    local try = 0
    while not win:size():equals(new_geometry) and try < 10 do
        win:setSize(new_geometry)
        hs.timer.usleep(100 * 1000)
        win:centerOnScreen()
        try = try + 1
    end
end

return M
