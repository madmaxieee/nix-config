local YABAI = "/run/current-system/sw/bin/yabai"

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

leader_bind("", "m", function()
    ToggleScratchpad("Messenger")
    leader_mode:exit()
end)

local function quick_note()
    hs.eventtap.keyStroke({ "fn" }, "q")
end
leader_bind("", "q", function()
    local app = hs.application.find("Notes", true)
    if app ~= nil and app:isFrontmost() then
        app:hide()
        return
    else
        quick_note()
    end
end)

-- open new arc windows
local function new_arc_window()
    local arc_app = hs.application.find("Arc", true)
    if arc_app == nil then
        hs.application.launchOrFocus("Arc")
    else
        hs.eventtap.keyStroke({ "command" }, "n", 0, arc_app)
    end
end
local function new_icognito_arc_window()
    local arc_app = hs.application.find("Arc", true)
    if arc_app == nil then
        hs.application.launchOrFocus("Arc")
    else
        hs.eventtap.keyStroke({ "command", "shift" }, "n", 0, arc_app)
    end
end
leader_bind("", "b", function()
    new_arc_window()
    leader_mode:exit()
end)
leader_bind("shift", "b", function()
    new_icognito_arc_window()
    leader_mode:exit()
end)

-- new kitty instance
leader_bind("", "return", function()
    os.execute([[/Applications/kitty.app/Contents/MacOS/kitty --single-instance --working-directory ~]])
    leader_mode:exit()
end)

-- yabai debug query
leader_bind("shift", "q", function()
    os.execute(YABAI .. [[ -m query --windows --space > /tmp/yabai-debug-query.json]])
    hs.alert("saved yabai query result")
    leader_mode:exit()
end)

-- toggle window float or sticky
leader_bind("", "f", function()
    os.execute(YABAI .. [[ -m window --toggle float]])
    leader_mode:exit()
end)
leader_bind("shift", "s", function()
    os.execute(YABAI .. [[ -m window --toggle sticky]])
    leader_mode:exit()
end)

-- interact with spaces
leader_bind("", "t", function()
    os.execute([[~/.config/yabai/new_space.sh]])
    leader_mode:exit()
end)
leader_bind("", "x", function()
    os.execute(YABAI .. [[ -m space --destroy mouse]])
    leader_mode:exit()
end)

local function go_to_space(space_index)
    os.execute(
        ([[~/.config/yabai/focus_window_in_space.sh ]] .. space_index)
            .. [[ || ]]
            .. (YABAI .. [[ -m space --focus ]] .. space_index)
    )
end
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
