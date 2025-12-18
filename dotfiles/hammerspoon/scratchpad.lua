local M = {}

hs.window.animationDuration = 0

---@param app_name string
---@param opts {bundle_id: boolean}?
function M.toggle_scratchpad(app_name, opts)
    opts = opts or {}

    local function launch_or_focus()
        if opts.bundle_id then
            hs.application.launchOrFocusByBundleID(app_name)
        else
            hs.application.launchOrFocus(app_name)
        end
    end

    local app = hs.application.find(app_name, true)
    if not app then
        launch_or_focus()
        return
    end

    local main_window = app:mainWindow()
    if not main_window then
        launch_or_focus()
        return
    end

    if app:isFrontmost() then
        require("wm").hide_window(main_window)
    else
        require("wm").move_window_to_current_space(main_window)
        require("wm").unhide_window(main_window)
    end
end

local hide_on_cmd_w_apps = {}

-- to make scratchpad work better
function M.hide_on_cmd_w(app_name)
    if hide_on_cmd_w_apps[app_name] then
        return
    end
    local app_bind = require("app_watch").app_bind
    app_bind(app_name, { "cmd" }, "w", function(app)
        if #app:allWindows() == 1 then
            require("wm").hide_window(app:mainWindow())
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
