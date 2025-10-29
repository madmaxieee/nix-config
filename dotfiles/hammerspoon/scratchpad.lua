local M = {}

hs.window.animationDuration = 0

function M.toggle_scratchpad(app_name)
    local app = hs.application.find(app_name, true)
    if not app then
        hs.application.launchOrFocus(app_name)
        return
    end

    local main_window = app:mainWindow()
    if not main_window then
        hs.application.launchOrFocus(app_name)
        return
    end

    if app:isFrontmost() then
        app:hide()
    else
        hs.execute([[PATH=]] .. PATH .. [[ ~/.config/yabai/move_window_to_current_space.sh ]] .. main_window:id())
        hs.spaces.moveWindowToSpace(main_window, hs.spaces.activeSpaceOnScreen())
        main_window:moveToScreen(hs.screen.mainScreen())
        app:activate()
    end
end

local hide_on_cmd_w_apps = {}

-- to make scratchpad work better
function M.hide_on_cmd_w(app_name)
    if hide_on_cmd_w_apps[app_name] then
        return
    end
    local app_bind = require("app_bind").app_bind
    app_bind(app_name, { "cmd" }, "w", function(app)
        if #app:allWindows() == 1 then
            app:hide()
        else
            app:focusedWindow():close()
        end
    end)
    app_bind(app_name, { "cmd", "shift" }, "w", function(app)
        app:focusedWindow():close()
    end)
    hide_on_cmd_w_apps[app_name] = true
end

return M
