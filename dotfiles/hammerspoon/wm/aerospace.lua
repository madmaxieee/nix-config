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
    -- aerospace debug query
    leader_bind("shift", "q", function()
        hs.execute(table.concat({
            aerospace_cmd "list-windows --all --json",
            ">/tmp/aerospace-debug-query.json",
        }, " "))
        hs.alert "saved aerospace query result"
    end)

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
    if app_name == "Google Chat" or app_name == "Google Gemini" or app_name == "T3 Chat" then
        return false
    end

    local bid = app:bundleID()
    if bid == "com.apple.finder" or bid == "com.apple.systempreferences" or bid == "com.culturedcode.ThingsMac" then
        return false
    end

    local win_title = win:title()
    if app_name == "kitty" and (win_title == "script kitty" or win_title == "scratch pad") then
        return false
    end

    return true
end

---@param window hs.window
function M.move_window_to_current_space(window)
    hs.execute([[PATH=]] .. PATH .. [[ ~/.config/aerospace/move_window_to_current_workspace.sh ]] .. window:id())
end

---@param window hs.window
function M.hide_window(window)
    -- use window:minimize() instead of app:hide() because aerospace
    -- doesn't work well with windows of hidden app
    window:minimize()
end

---@param window hs.window
function M.unhide_window(window)
    window:unminimize()
    window:focus()
end

local MAX_RESIZE_RETRIES = 10

---@param win_id number
---@param match {app:string?, title:string?}
---@param size {width:number, height:number}
function TryResizeWindow(win_id, match, size)
    local win = hs.window.get(win_id)
    if not win then
        return
    end
    if match.title then
        if win:title() ~= match.title then
            return
        end
    end
    if match.app then
        local app = win:application()
        if not app or app:name() ~= match.app then
            return
        end
    end
    -- do resize
    local new_geometry = hs.geometry.size(size.width, size.height)
    if win:size():equals(new_geometry) then
        win:centerOnScreen()
        return
    end
    local try = 0
    while not win:size():equals(new_geometry) and try < MAX_RESIZE_RETRIES do
        win:setSize(new_geometry)
        hs.timer.usleep(100 * 1000)
        win:centerOnScreen()
        try = try + 1
    end
end

function TryResizeScriptKitty(win_id)
    TryResizeWindow(win_id, { app = "kitty", title = "script kitty" }, { width = 900, height = 600 })
end

function TryResizeScratchPad(win_id)
    TryResizeWindow(win_id, { app = "kitty", title = "scratch pad" }, { width = 1200, height = 800 })
end

return M
