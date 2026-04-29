local path = "PATH=" .. PATH .. " "

local scratchpad = require("scratchpad")
local config = require("my_config")

local leader_mode = require("leader_mode")
local leader_bind = leader_mode.bind
local leader_exit = leader_mode.exit

leader_bind("", "escape", function()
    leader_exit()
end)

if config.message_app then
    scratchpad.hide_on_cmd_w(config.message_app)
    leader_bind("", "m", function()
        scratchpad.toggle_app_scratchpad(config.message_app)
    end)
end

if config.ai_app then
    scratchpad.hide_on_cmd_w(config.ai_app)
    leader_bind("", "g", function()
        scratchpad.toggle_app_scratchpad(config.ai_app)
    end)
end

if config.todo_app then
    scratchpad.hide_on_cmd_w(config.todo_app)
    leader_bind("", "t", function()
        scratchpad.toggle_app_scratchpad(config.todo_app)
    end)
end

leader_bind("", "n", function()
    scratchpad.toggle_scratchpad({
        find_window = function()
            local app = hs.application.get("net.kovidgoyal.kitty")
            if not app then
                return nil
            end
            return app:getWindow("obsidian")
        end,
        launch = function()
            os.execute(
                path
                    .. [[kitty --single-instance --title='obsidian' ~/.hammerspoon/quick-obsidian.sh &]]
            )
        end,
        hide = function(window)
            window:minimize()
        end,
    })
end)

hs.hotkey.bind({ "cmd" }, ".", function()
    scratchpad.toggle_scratchpad({
        find_window = function()
            local app = hs.application.get("net.kovidgoyal.kitty")
            if not app then
                return nil
            end
            return app:getWindow("scratch pad")
        end,
        launch = function()
            os.execute(
                path
                    .. [[kitty --single-instance --title='scratch pad' nvim +startinsert /tmp/scratch-pad.md &]]
            )
        end,
        hide = function(window)
            window:minimize()
        end,
    })
end)

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
if config.browser then
    leader_bind("", "b", function()
        new_browser_window()
    end)
    leader_bind("shift", "b", function()
        new_icognito_browser_window()
    end)
end

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

local is_managed = require("wm").is_managed

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
    if win and is_managed(win:id()) then
        return
    end
    TryCenterWindow(win)
end)
leader_bind("shift", "c", function()
    focused_window():centerOnScreen()
end)

-- lock mode to avoid triggering shift-space
local lock_mode = hs.hotkey.modal.new({ "ctrl", "cmd", "shift" }, "space")

function lock_mode:entered()
    hs.alert("entered lock mode")
    leader_exit()
end
function lock_mode:exited()
    hs.alert("exited lock mode")
end

lock_mode:bind({ "ctrl", "cmd", "shift" }, "space", function()
    lock_mode:exit()
end)

-- shadow leader mode keybinding
lock_mode:bind({ "shift" }, "space", function()
    hs.alert("lock mode activated")
end)

-- apply hide_on_cmd_w for all chrome PWAs
local pwa_bundle_id_prefix = "com.google.Chrome.app."

---@param app_name string
---@param event_type any
---@param app hs.application
PWAAppWatcher = hs.application.watcher.new(function(app_name, event_type, app)
    if event_type == hs.application.watcher.launching then
        if
            app:bundleID():sub(1, #pwa_bundle_id_prefix)
                == pwa_bundle_id_prefix
            and app:name() ~= "Cider"
        then
            scratchpad.hide_on_cmd_w(app_name)
        end
    end
end)
PWAAppWatcher:start()
