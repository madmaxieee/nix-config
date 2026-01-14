local M = {}

local leader_mode = hs.hotkey.modal.new("shift", "space")

-- disable leader mode when the last key is not pressed in 1 second
local last_defer_time = 0
local function defer_exit_leader(second)
    local current_time = hs.timer.absoluteTime()
    -- this current time is bind to this specific callback
    -- would only exit when the leader key is not pressed in the next 1 second
    ---@diagnostic disable-next-line: cast-local-type
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

---@class LeaderBindOpts
---@field repeatable boolean

---@param modifiers string
---@param key string
---@param callback function
---@param opts LeaderBindOpts?
function M.bind(modifiers, key, callback, opts)
    opts = opts or {}
    opts.repeatable = opts.repeatable or false
    local key_str = modifiers .. "+" .. key
    if bound_keys[key_str] then
        local error_msg
        if modifiers == "" then
            error_msg = "key '" .. key .. "' is already bound"
        else
            error_msg = "key '"
                .. modifiers
                .. " "
                .. key
                .. "' is already bound"
        end
        error(error_msg)
        return
    end
    leader_mode:bind(modifiers, key, function()
        last_defer_time = 0
        callback()
        if not opts.repeatable then
            leader_mode:exit()
        end
    end)
    bound_keys[key_str] = true
end

function M.exit()
    leader_mode:exit()
end

return M
