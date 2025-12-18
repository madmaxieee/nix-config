local M = { name = "yabai" }

local path = "PATH=" .. PATH .. " "
local yabai = path .. "yabai"

local leader_mode = require "leader_mode"
local leader_bind = leader_mode.bind
local leader_exit = leader_mode.exit

-- interact with spaces
local function go_to_space(space_sel)
    -- don't call ~/.config/yabai/focus_space.sh directly
    -- calling hammerspoon in a script invoke by hammerspoon causes problem
    local success = os.execute(
        (path .. [[~/.config/yabai/focus_window_in_space.sh ]] .. space_sel)
            .. [[ || ]]
            .. (yabai .. [[ -m space --focus ]] .. space_sel)
            .. [[ || ]]
            .. (
                yabai
                .. [[ -m query --spaces has-focus --space ]]
                .. space_sel
                .. [[ | ]]
                .. path
                .. [[jq -e '."has-focus"']]
            )
    )

    -- the previous command would fail with sip enabled
    -- if that's the case use hammerspoon to focus space instead
    if not success then
        local space_id =
            hs.execute(yabai .. [[ -m query --spaces id --space ]] .. space_sel .. [[ | ]] .. path .. [[jq .id]])
        space_id = tonumber(space_id)
        hs.spaces.gotoSpace(space_id)
    end
end

function M.setup()
    -- yabai debug query
    leader_bind("shift", "q", function()
        os.execute(yabai .. [[ -m query --windows --space > /tmp/yabai-debug-query.json]])
        hs.alert "saved yabai query result"
    end)

    -- toggle window float or sticky
    leader_bind("", "f", function()
        os.execute(yabai .. [[ -m window --toggle float]])
    end)
    leader_bind("shift", "s", function()
        os.execute(yabai .. [[ -m window --toggle sticky]])
    end)

    leader_bind("", "x", function()
        local success = os.execute(yabai .. [[ -m space --destroy]])
        leader_exit()
        if not success then
            local space_id = hs.spaces.activeSpaceOnScreen()
            go_to_space "recent"
            hs.timer.usleep(400 * 1000)
            hs.spaces.removeSpace(space_id)
        end
    end)

    leader_bind("", "r", function()
        go_to_space "recent"
    end)
    leader_bind("", "l", function()
        go_to_space "next"
    end, { repeatable = true })
    leader_bind("", "h", function()
        go_to_space "prev"
    end, { repeatable = true })
    for i = 1, 9 do
        leader_bind("", tostring(i), function()
            go_to_space(i)
        end)
    end
    leader_bind("", "0", function()
        go_to_space(10)
    end)
end

function M.is_managed(win_id)
    local win_info_raw = hs.execute((yabai .. [[ -m query --windows --window %d]]):format(win_id))
    local win_info = hs.json.decode(win_info_raw)
    if win_info == nil then
        return false
    end
    return not win_info["is-floating"]
end

---@param window hs.window
function M.move_window_to_current_space(window)
    hs.execute([[PATH=]] .. PATH .. [[ ~/.config/yabai/move_window_to_current_space.sh ]] .. window:id())
    hs.spaces.moveWindowToSpace(window, hs.spaces.activeSpaceOnScreen())
    window:moveToScreen(hs.screen.mainScreen())
end

---@param window hs.window
function M.hide_window(window)
    -- app:hide() instead of window:hide() because the animation is faster
    local app = window:application()
    if not app then
        return
    end
    app:hide()
end

return M
