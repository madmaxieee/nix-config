ToggleAppScratchpad = require("scratchpad").toggle_app_scratchpad

function BundleId(hint)
    return hs.application.find(hint):bundleID()
end

---@param win_or_win_id hs.window|number
---@param w? number
---@param h? number
function TryCenterWindow(win_or_win_id, w, h)
    local win
    if type(win_or_win_id) == "number" then
        win = hs.window.get(win_or_win_id)
    else
        win = win_or_win_id
    end
    if not win then
        return
    end
    if not (w and h) then
        w = 1350
        h = 900
    end

    local new_geometry = hs.geometry.size(w, h)
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
