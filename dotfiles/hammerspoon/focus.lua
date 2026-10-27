local M = {}
local wm = require("wm")

---@type table<string, hs.window>
local previous_windows = {}

---@param window hs.window?
local function focus_window_space(window)
    if wm.name ~= "yabai" then
        return
    end

    local window_id = window and window:id()
    if not window_id then
        return
    end

    local path = (PATH or os.getenv("PATH") or ""):gsub("'", "'\\''")
    local command = "PATH='" .. path .. "' yabai -m "
    local output, success = hs.execute(
        command .. ("query --windows --window %d 2>/dev/null"):format(window_id)
    )
    if not success then
        return
    end

    local info = hs.json.decode(output)
    if
        info
        and info.space
        and not info["is-visible"]
        and not info["is-sticky"]
    then
        hs.execute(
            command .. ("space --focus %d 2>/dev/null"):format(info.space)
        )
    end
end

---@param app_name string Application name or bundle ID.
function M.toggle_app_focus(app_name)
    local window = hs.window.focusedWindow()
    local is_bundle_id = string.find(app_name, ".", 1, true) ~= nil
    local app
    if is_bundle_id then
        app = hs.application.get(app_name)
    else
        app = hs.application.find(app_name, true)
    end

    if window and app and window:application():pid() == app:pid() then
        local previous_window = previous_windows[app_name]
        if previous_window and previous_window:id() then
            focus_window_space(previous_window)
            previous_window:focus()
        end
        return
    end

    previous_windows[app_name] = window
    if app then
        focus_window_space(app:focusedWindow() or app:mainWindow())
    end
    if is_bundle_id then
        hs.application.launchOrFocusByBundleID(app_name)
    else
        hs.application.launchOrFocus(app_name)
    end
end

return M
