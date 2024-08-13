local function toggle_scratchpad(app_name)
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
        return
    else
        local window_id = main_window:id()
        os.execute([[~/.config/yabai/move_window_to_current_space.sh ]] .. window_id)
        app:activate()
    end
end

return toggle_scratchpad
