local colors = require "colors"
local app_icons = require "icon_map"

local function truncate_string(str, n)
    if #str > n then
        return str:sub(1, n - 3) .. "..."
    else
        return str
    end
end

local whitelist = {
    ["Spotify"] = colors.green,
    ["Podcasts"] = colors.magenta,
}

---@class MediaState
---@field enabled boolean
---@field current_app string?
---@field artist string
---@field title string
---@field label string
local state = {
    enabled = true,
    current_app = nil,
    artist = "",
    title = "",
    label = "",
}

local media = sbar.add("item", "media", {
    icon = {
        font = "sketchybar-app-font:Regular:14.0",
        padding_left = 12,
        padding_right = 12,
        y_offset = -1,
    },
    label = { padding_right = 12, font = { size = 14.0 } },
    position = "center",
    updates = true,
})

local function get_app_icon(app)
    local lookup = app_icons[app]
    local icon = (lookup and lookup or app_icons["Default"])
    return icon
end

media:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "left" then
        if state.current_app == "Spotify" then
            sbar.exec [[hs -c 'hs.spotify.playpause()']]
        elseif state.current_app == "Podcasts" then
            sbar.exec [[hs -c 'hs.eventtap.keyStroke({}, "space", 0, hs.application.find("Podcasts"))']]
        else
            sbar.exec [[hs -c 'hs.eventtap.event.newSystemKeyEvent("PLAY", true):post()']]
        end
    elseif env.BUTTON == "right" then
        sbar.exec([[hs -c '
            local app = hs.application.find("]] .. state.current_app .. [[");
            if app:isFrontmost() and app:mainWindow() then
                app:mainWindow():close()
            else
                hs.application.launchOrFocus(app:name())
            end
        ']])
    end
end)

media:subscribe("media_change", function(env)
    local app_color = whitelist[env.INFO.app]
    if app_color ~= nil then
        state.current_app = env.INFO.app
        state.artist = (env.INFO.artist ~= "" and env.INFO.artist) or "Unknown Artist"
        state.title = (env.INFO.title ~= "" and truncate_string(env.INFO.title, 50)) or "Unknown Title"
        local playback_icon = ((env.INFO.state == "playing") and "" or "")
        state.label = playback_icon .. "  " .. state.artist .. ": " .. state.title

        if not state.enabled then
            return
        end

        sbar.animate("tanh", 10, function()
            media:set {
                icon = { string = get_app_icon(state.current_app), color = app_color },
                label = { string = state.label },
            }
        end)
    end
end)

---@diagnostic disable-next-line: unused-local
media:subscribe("media_toggle", function(env)
    state.enabled = not state.enabled
    if state.enabled and state.current_app then
        sbar.animate("tanh", 10, function()
            media:set {
                icon = {
                    string = get_app_icon(state.current_app),
                    color = whitelist[state.current_app],
                },
                label = { string = state.label },
            }
        end)
    else
        sbar.animate("tanh", 10, function()
            media:set { icon = { string = "" }, label = { string = "" } }
        end)
    end
end)
