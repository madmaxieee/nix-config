local M = {}

local leader_mode = require "leader_mode"
local leader_bind = leader_mode.bind

local function aerospace_cmd(cmd)
    return ("PATH=%s aerospace %s"):format(PATH, cmd)
end

local function aerospace(args)
    return hs.execute(aerospace_cmd(args))
end

function M.setup()
    leader_bind("", "r", function()
        aerospace "workspace-back-and-forth"
    end)

    leader_bind("", "l", function()
        hs.execute(table.concat({
            aerospace_cmd "list-workspaces --all",
            "|",
            aerospace_cmd "workspace --wrap-around --stdin next",
        }, " "))
    end)
    leader_bind("", "h", function()
        hs.execute(table.concat({
            aerospace_cmd "list-workspaces --all",
            "|",
            aerospace_cmd "workspace --wrap-around --stdin prev",
        }, " "))
    end)

    for i = 1, 9 do
        leader_bind("", tostring(i), function()
            aerospace("workspace " .. tostring(i))
        end)
    end
    leader_bind("", "0", function()
        aerospace "workspace 10"
    end)
end

---@diagnostic disable-next-line: unused-local
function M.is_managed(win_id)
    return false
end

return M
