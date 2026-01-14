local sbar = require("sketchybar")
local colors = require("colors")

local M = {}

local function formatBytes(bytes)
    if bytes == 0 then
        return "0 b"
    end

    local k = 1024
    local dm = 1
    local sizes = { "b", "kb", "mb", "gb", "tb", "pb", "eb", "zb", "yb" }

    local i = math.floor(math.log(bytes) / math.log(k))

    local value = bytes / (k ^ i)
    if value >= 100 then
        dm = 0
    end
    local formattedValue = string.format("%." .. dm .. "f", value)

    return string.format("%s %s", formattedValue, sizes[i + 1])
end

function M.setup(opts)
    opts = opts or {}
    local position = opts.position

    local netstat_up = sbar.add("item", {
        position = position,
        width = 66,
        icon = { drawing = false },
        label = { color = colors.blue },
    })
    sbar.add("item", {
        position = position,
        icon = {
            string = "",
            font = { size = 14 },
            color = colors.blue,
            padding_right = 0,
        },
        label = { drawing = false },
    })
    local netstat_down = sbar.add("item", {
        position = position,
        width = 66,
        icon = { drawing = false },
        label = { color = colors.red },
    })
    sbar.add("item", {
        position = position,
        icon = {
            string = "",
            font = { size = 14 },
            color = colors.red,
            padding_right = 0,
        },
        label = { drawing = false },
    })
    M.netstat_up = netstat_up
    M.netstat_down = netstat_down

    sbar.exec("~/.config/sketchybar/items/netstat.sh")

    netstat_up:subscribe("netstat_update", function(env)
        local download = formatBytes(env.DOWNLOAD)
        local upload = formatBytes(env.UPLOAD)
        netstat_up:set({
            label = { string = upload },
        })
        netstat_down:set({
            label = { string = download },
        })
    end)
end

return M
