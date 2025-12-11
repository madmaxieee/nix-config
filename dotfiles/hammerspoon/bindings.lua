local path = "PATH=" .. PATH .. " "
local yabai = path .. "yabai"

local scratchpad = require "scratchpad"
local config = require "my_config"

local leader_mode = require "leader_mode"
local leader_bind = leader_mode.bind
local leader_exit = leader_mode.exit

leader_bind("", "escape", function()
    leader_exit()
end)

if config.message_app then
    scratchpad.hide_on_cmd_w(config.message_app)
    leader_bind("", "m", function()
        scratchpad.toggle_scratchpad(config.message_app)
    end)
end

if config.note_app then
    scratchpad.hide_on_cmd_w(config.note_app)
    leader_bind("", "n", function()
        scratchpad.toggle_scratchpad(config.note_app)
    end)
end

if config.ai_app then
    scratchpad.hide_on_cmd_w(config.ai_app)
    leader_bind("", "g", function()
        scratchpad.toggle_scratchpad(config.ai_app)
    end)
end

-- open new browser windows
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
end)
leader_bind("shift", "b", function()
    new_icognito_browser_window()
end)

-- new terminal instance
if config.terminal_app == "kitty" then
    leader_bind("", "return", function()
        os.execute(path .. [[kitty --single-instance --working-directory ~ &]])
    end)
else
    leader_bind("", "return", function()
        local terminal_name = config.terminal_app
        local terminal_app = hs.application.find(terminal_name, true)
        if not terminal_app then
            hs.application.launchOrFocus(terminal_name)
            return
        end
        local main_window = terminal_app:mainWindow()
        if not main_window then
            hs.application.launchOrFocus(terminal_name)
            return
        end
        hs.eventtap.keyStroke({ "command" }, "n", 0, terminal_app)
    end)
end

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

-- leader_bind("", "t", function()
--     -- don't call new_space directly as it uses focus_space under the hood
--     local success = os.execute(yabai .. [[ -m space --create]])
--     if not success then
--         hs.spaces.addSpaceToScreen("main", false)
--     end
--     local new_space_index = hs.execute(
--         yabai
--             .. [[ -m query --spaces --display]]
--             .. [[|]]
--             .. path
--             .. [[ jq 'map(select(."is-native-fullscreen" == false))[-1].index']]
--     )
--     new_space_index = tonumber(new_space_index)
--     go_to_space(new_space_index)
-- end)

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
end)
leader_bind("", "h", function()
    go_to_space "prev"
end)
for i = 1, 9 do
    leader_bind("", tostring(i), function()
        go_to_space(i)
    end)
end
leader_bind("", "0", function()
    go_to_space(10)
end)

local function is_managed_by_yabai(win_id)
    local win_info_raw = hs.execute((yabai .. [[ -m query --windows --window %d]]):format(win_id))
    local win_info = hs.json.decode(win_info_raw)
    if win_info == nil then
        return false
    end
    return not win_info["is-floating"]
end

---@param win hs.window
---@param delta_ratio number
local function relative_resize_keep_aspect(win, delta_ratio)
    local frame = win:frame()
    local new_w = frame.w * (1 + delta_ratio)
    local new_h = frame.h * (1 + delta_ratio)
    local new_x = frame.x - (new_w - frame.w) / 2
    local new_y = frame.y - (new_h - frame.h) / 2
    win:setFrame(hs.geometry.rect(new_x, new_y, new_w, new_h))
end

---@return hs.window
local function focused_window()
    local app = hs.application.frontmostApplication()
    local win = app:focusedWindow()
    return win
end

leader_bind("", "-", function()
    relative_resize_keep_aspect(focused_window(), -0.1)
end, { repeatable = true })
leader_bind("shift", "=", function()
    relative_resize_keep_aspect(focused_window(), 0.1)
end, { repeatable = true })
leader_bind("", "=", function()
    relative_resize_keep_aspect(focused_window(), 0.1)
end, { repeatable = true })
leader_bind("", "c", function()
    local win = focused_window()
    if is_managed_by_yabai(win:id()) then
        return
    end
    local new_geometry = hs.geometry.size(1350, 900)
    if win:size():equals(new_geometry) then
        win:centerOnScreen()
        return
    end
    while not win:size():equals(new_geometry) do
        win:setSize(new_geometry)
        hs.timer.usleep(100 * 1000)
        win:centerOnScreen()
    end
end)
leader_bind("shift", "c", function()
    focused_window():centerOnScreen()
end)

-- lock mode to avoid triggering shift-space
local lock_mode = hs.hotkey.modal.new("ctrl-shift", "space")

function lock_mode:entered()
    hs.alert "entered lock mode"
    leader_exit()
end
function lock_mode:exited()
    hs.alert "exited lock mode"
end

lock_mode:bind({ "ctrl", "shift" }, "space", function()
    lock_mode:exit()
end)

-- shadow leader mode keybinding
lock_mode:bind({ "shift" }, "space", function()
    hs.alert "lock mode activated"
end)

-- non-modal key binding
hs.hotkey.bind({ "cmd" }, ";", function()
    os.execute(path .. [[~/nix-config/dotfiles/script-kitty/script-kitty-prompt &]])
end)

-- app specific key binding
local app_bind = require("app_bind").app_bind

app_bind("Zen", { "cmd" }, "d", function(app)
    -- pin and unpin tab, this is currently not customizable in Zen
    hs.eventtap.keyStroke({ "alt" }, "p", 0, app)
end)

-- apply hide_on_cmd_w for all chrome PWAs
local pwa_bundle_id_prefix = "com.google.Chrome.app."

---@param app_name string
---@param event_type any
---@param app hs.application
PWAAppWatcher = hs.application.watcher.new(function(app_name, event_type, app)
    if event_type == hs.application.watcher.launching then
        if app:bundleID():sub(1, #pwa_bundle_id_prefix) == pwa_bundle_id_prefix then
            scratchpad.hide_on_cmd_w(app_name)
        end
    end
end)
PWAAppWatcher:start()
