local M = {}

hs.window.animationDuration = 0

M.toggle_scratchpad = function(app_name)
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
        hs.spaces.moveWindowToSpace(main_window, hs.spaces.activeSpaceOnScreen())
        main_window:moveToScreen(hs.screen.mainScreen())
        os.execute([[PATH=]] .. PATH .. [[ ~/.config/yabai/move_window_to_current_space.sh ]] .. main_window:id())
        app:activate()
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
