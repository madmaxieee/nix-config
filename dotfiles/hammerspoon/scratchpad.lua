local M = {}

hs.window.animationDuration = 0

---@class ScratchpadOpts
---@field window_title string?
---@field launch_fn function?

---@param app_name string: the name of the application to toggle
---@param opts ScratchpadOpts?
M.toggle_scratchpad = function(app_name, opts)
    opts = opts or {}

    local launch = function()
        if opts.launch_fn then
            opts.launch_fn()
        else
            hs.application.launchOrFocus(app_name)
        end
    end

    local find_window = function(app)
        if not opts.window_title then
            return app:mainWindow(), app
        end
        local window = hs.appfinder.windowFromWindowTitle(opts.window_title)
        if window == nil then
            return nil, nil
        end
        app = window:application()
        if app:name() == app_name then
            return window, app
        end
    end

    ---@type hs.application?
    local app = hs.application.find(app_name, true)
    if not app then
        launch()
        return
    end

    local window = nil
    window, app = find_window(app)
    if not window or not app then
        launch()
        return
    end

    if window:id() == hs.window.frontmostWindow():id() then
        app:hide()
    else
        hs.execute([[PATH=]] .. PATH .. [[ ~/.config/yabai/move_window_to_current_space.sh ]] .. window:id())
        hs.spaces.moveWindowToSpace(window, hs.spaces.activeSpaceOnScreen())
        window:moveToScreen(hs.screen.mainScreen())
        window:focus():raise()
    end
end

-- to make scratchpad work better
M.hide_on_cmd_w = function(app_name)
    require("app_bind").app_bind(app_name, { "cmd" }, "w", function()
        local app = hs.application.frontmostApplication()
        local num_windows = #app:allWindows()
        if num_windows == 1 then
            app:hide()
        else
            app:focusedWindow():close()
        end
    end)
end

return M
