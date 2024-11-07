local path = "PATH=" .. PATH .. " HAMMERSPOON=1 "
local yabai = path .. "yabai"

local scratchpad = require("scratchpad")
local config = require("my_config")

local leader_mode = hs.hotkey.modal.new("shift", "space")

-- disable leader mode when the last key is not pressed in 1 second
local last_defer_time = 0
local function defer_exit_leader(second)
    local current_time = hs.timer.absoluteTime()
    -- this current time is bind to this specific callback
    -- would only exit when the leader key is not pressed in the next 1 second
    last_defer_time = current_time
    hs.timer.doAfter(second, function()
        if last_defer_time == current_time then
            leader_mode:exit()
        end
    end)
end

function leader_mode:entered()
    defer_exit_leader(1)
end

local bound_keys = {}
local function leader_bind(modifiers, key, callback)
    local key_str = modifiers .. "+" .. key
    if bound_keys[key_str] then
        local error_msg
        if modifiers == "" then
            error_msg = "key '" .. key .. "' is already bound"
        else
            error_msg = "key '" .. modifiers .. " " .. key .. "' is already bound"
        end
        error(error_msg)
        return
    end
    leader_mode:bind(modifiers, key, function()
        last_defer_time = 0
        callback()
    end)
    bound_keys[key_str] = true
end

leader_bind("", "escape", function()
    leader_mode:exit()
end)

scratchpad.hide_on_cmd_w(config.message_app)
leader_bind("", "m", function()
    scratchpad.toggle_scratchpad(config.message_app)
    leader_mode:exit()
end)

local function quick_note()
    hs.eventtap.keyStroke({ "fn" }, "q")
end
leader_bind("", "q", function()
    local app = hs.application.find("Notes", true)
    if app ~= nil and app:isFrontmost() then
        app:hide()
    else
        quick_note()
    end
    leader_mode:exit()
end)

-- open new arc windows
local function new_browser_window()
    local browser_app = hs.application.find(config.browser, true)
    if browser_app == nil then
        hs.application.launchOrFocus(config.browser)
    else
        hs.eventtap.keyStroke({ "command" }, "n", 0, browser_app)
    end
end
local function new_icognito_browser_window()
    local browser_app = hs.application.find(config.browser, true)
    if browser_app == nil then
        hs.application.launchOrFocus(config.browser)
    else
        hs.eventtap.keyStroke({ "command", "shift" }, "n", 0, browser_app)
    end
end
leader_bind("", "b", function()
    new_browser_window()
    leader_mode:exit()
end)
leader_bind("shift", "b", function()
    new_icognito_browser_window()
    leader_mode:exit()
end)

-- new kitty instance
leader_bind("", "return", function()
    os.execute(path .. [[kitty --single-instance --working-directory ~ &]])
    leader_mode:exit()
end)

-- yabai debug query
leader_bind("shift", "q", function()
    os.execute(yabai .. [[ -m query --windows --space > /tmp/yabai-debug-query.json]])
    hs.alert("saved yabai query result")
    leader_mode:exit()
end)

-- toggle window float or sticky
leader_bind("", "f", function()
    os.execute(yabai .. [[ -m window --toggle float]])
    leader_mode:exit()
end)
leader_bind("shift", "s", function()
    os.execute(yabai .. [[ -m window --toggle sticky]])
    leader_mode:exit()
end)

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
leader_bind("", "t", function()
    -- don't call new_space directly as it uses focus_space under the hood
    local success = os.execute(yabai .. [[ -m space --create]])
    if not success then
        hs.spaces.addSpaceToScreen("main", false)
    end
    local new_space_index = hs.execute(
        yabai
            .. [[ -m query --spaces --display]]
            .. [[|]]
            .. path
            .. [[ jq 'map(select(."is-native-fullscreen" == false))[-1].index']]
    )
    new_space_index = tonumber(new_space_index)
    go_to_space(new_space_index)
    leader_mode:exit()
end)
leader_bind("", "x", function()
    leader_mode:exit()
    local success = os.execute(yabai .. [[ -m space --destroy]])
    if not success then
        local space_id = hs.spaces.activeSpaceOnScreen()
        go_to_space("recent")
        hs.timer.usleep(400 * 1000)
        hs.spaces.removeSpace(space_id)
    end
end)
leader_bind("", "r", function()
    go_to_space("recent")
    leader_mode:exit()
end)
leader_bind("", "l", function()
    go_to_space("next")
    leader_mode:exit()
end)
leader_bind("", "h", function()
    go_to_space("prev")
    leader_mode:exit()
end)
for i = 1, 9 do
    leader_bind("", tostring(i), function()
        go_to_space(i)
        leader_mode:exit()
    end)
end
leader_bind("", "0", function()
    go_to_space(10)
    leader_mode:exit()
end)

local function open_bg(url)
    os.execute([[open -g ']] .. url .. [[']])
end

-- raycast window management for floating windows
leader_bind("", "-", function()
    open_bg("raycast://extensions/raycast/window-management/make-smaller")
end)
leader_bind("", "=", function()
    open_bg("raycast://extensions/raycast/window-management/make-larger")
end)
leader_bind("", "c", function()
    open_bg("raycast://extensions/raycast/window-management/center")
    leader_mode:exit()
end)

-- lock mode to avoid triggering shift-space
local lock_mode = hs.hotkey.modal.new("ctrl-shift", "space")

function lock_mode:entered()
    hs.alert("entered lock mode")
    leader_mode:exit()
end
function lock_mode:exited()
    hs.alert("exited lock mode")
    leader_mode:exit()
end

lock_mode:bind({ "ctrl", "shift" }, "space", function()
    lock_mode:exit()
end)

-- shadow leader mode keybinding
lock_mode:bind({ "shift" }, "space", function()
    hs.alert("lock mode activated")
end)
