local colors = require "colors"
local app_icons = require "icon_map"

local whitelist = {
    ["Spotify"] = colors.green,
    ["Podcasts"] = colors.magenta,
}

---@class MediaState
---@field enabled boolean
---@field current_app string?
---@field playing boolean
---@field artist string
---@field title string
---@field label string
local state = {
    enabled = true,
    current_app = nil,
    playing = false,
    artist = "",
    title = "",
    label = "",
}

local last_track_button = sbar.add("item", "last_track_button", {
    icon = {
        font = { size = 14 },
        color = colors.white,
        width = 12,
    },
    position = "center",
    padding_left = 0,
    padding_right = 0,
    drawing = false,
})

local play_button = sbar.add("item", "play_button", {
    icon = {
        font = { size = 12 },
        color = colors.white,
        width = 12,
    },
    position = "center",
    padding_left = 0,
    padding_right = 0,
})

local next_track_button = sbar.add("item", "next_track_button", {
    icon = {
        font = { size = 12 },
        color = colors.white,
        width = 12,
    },
    position = "center",
    padding_left = 0,
    padding_right = 0,
    drawing = false,
})

local media = sbar.add("item", "media", {
    icon = {
        font = {
            family = "sketchybar-app-font",
            style = "Regular",
            size = 12,
        },
        padding_left = 0,
        padding_right = 8,
        y_offset = -1,
    },
    label = {
        padding_right = 12,
        font = { size = 14 },
        max_chars = 40,
    },
    position = "center",
    scroll_texts = true,
    padding_left = 8,
})

local function get_app_icon(app)
    local lookup = app_icons[app]
    local icon = (lookup and lookup or app_icons["Default"])
    return icon
end

local function rerender_media()
    if state.enabled and state.current_app then
        sbar.animate("tanh", 10, function()
            last_track_button:set { icon = { string = "" } }
            play_button:set { icon = { string = state.playing and "" or "" } }
            next_track_button:set { icon = { string = "" } }
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
            last_track_button:set { icon = { string = "" } }
            play_button:set { icon = { string = "" } }
            next_track_button:set { icon = { string = "" } }
            media:set { icon = { string = "" }, label = { string = "" } }
        end)
    end
end

local function play_pause()
    if state.current_app == "Spotify" then
        sbar.exec [[hs -c 'hs.spotify.playpause()']]
    elseif state.current_app == "Podcasts" then
        sbar.exec [[hs -c 'hs.eventtap.keyStroke({}, "space", 0, hs.application.find("Podcasts"))']]
    else
        sbar.exec [[hs -c 'hs.eventtap.event.newSystemKeyEvent("PLAY", true):post()']]
    end
end

local function toggle_app()
    sbar.exec([[hs -c '
            local app = hs.application.find("]] .. state.current_app .. [[");
            if app:isFrontmost() and app:mainWindow() then
                app:mainWindow():close()
            else
                hs.application.launchOrFocus(app:name())
            end
        ']])
end

play_button:subscribe("mouse.clicked", play_pause)

local function next_track()
    if state.current_app == "Spotify" then
        sbar.exec [[hs -c 'hs.spotify.next()']]
    elseif state.current_app == "Podcasts" then
        sbar.exec [[hs -c 'hs.eventtap.keyStroke({"cmd"}, "right", 0, hs.application.find("Podcasts"))']]
    else
        sbar.exec [[hs -c 'hs.eventtap.event.newSystemKeyEvent("NEXT", true):post()']]
    end
end

local function last_track()
    if state.current_app == "Spotify" then
        sbar.exec [[hs -c 'hs.spotify.previous()']]
    elseif state.current_app == "Podcasts" then
        sbar.exec [[hs -c 'hs.eventtap.keyStroke({"cmd"}, "left", 0, hs.application.find("Podcasts"))']]
    else
        sbar.exec [[hs -c 'hs.eventtap.event.newSystemKeyEvent("PREVIOUS", true):post()']]
    end
end

last_track_button:subscribe("mouse.clicked", last_track)
next_track_button:subscribe("mouse.clicked", next_track)

media:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "left" then
        play_pause()
    elseif env.BUTTON == "right" then
        toggle_app()
    end
end)

media:subscribe("media_change", function(env)
    local app_color = whitelist[env.INFO.app]
    if app_color ~= nil then
        state.current_app = env.INFO.app
        state.artist = (env.INFO.artist ~= "" and env.INFO.artist) or "Unknown Artist"
        state.title = (env.INFO.title ~= "" and env.INFO.title) or "Unknown Title"
        state.playing = env.INFO.state == "playing"
        state.label = state.artist .. ": " .. state.title
        rerender_media()
    end
end)

---@diagnostic disable-next-line: unused-local
media:subscribe("media_toggle", function(env)
    state.enabled = not state.enabled
    rerender_media()
end)
