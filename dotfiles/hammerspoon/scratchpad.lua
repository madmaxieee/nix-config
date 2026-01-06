local M = {}

hs.window.animationDuration = 0

---@alias WindowFinder fun(): hs.window?
---@alias WindowLauncher fun(): nil
---@alias WindowHider fun(window: hs.window): nil

---@param opts {find_window: WindowFinder, launch: WindowLauncher, hide: WindowHider}
function M.toggle_scratchpad(opts)
    local window = opts.find_window()
    if not window then
        opts.launch()
        return
    end

    local focused_window = hs.window.focusedWindow()

    if focused_window and focused_window:id() == window:id() then
        opts.hide(window)
    else
        require("wm").move_window_to_current_space(window)
        window:focus()
        window:unminimize() -- noop if not minimize
    end
end

---@param app_name string
---@param opts {bundle_id: boolean}?
function M.toggle_app_scratchpad(app_name, opts)
    opts = opts or {}
    M.toggle_scratchpad {
        find_window = function()
            local app
            if opts.bundle_id then
                app = hs.application.get(app_name)
            else
                app = hs.application.find(app_name, true)
            end
            if not app then
                return nil
            end
            return app:mainWindow()
        end,
        launch = function()
            if opts.bundle_id then
                hs.application.launchOrFocusByBundleID(app_name)
            else
                hs.application.launchOrFocus(app_name)
            end
        end,
        hide = function(window)
            require("wm").hide_window(window)
        end,
    }
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
