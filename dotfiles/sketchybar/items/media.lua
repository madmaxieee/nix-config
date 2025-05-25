local sbar = require "sketchybar"
local colors = require "colors"
local app_icons = require "icon_map"

local M = {}

local whitelist = {
    ["Spotify"] = colors.green,
    ["Podcasts"] = colors.magenta,
}

---@class MediaState
---@field enabled boolean
---@field current_app string?
---@field playing boolean
---@field artist string?
---@field title string?
local state = {
    enabled = true,
    current_app = nil,
    playing = false,
    artist = "",
    title = "",
}
M.state = state

local function get_app_icon(app)
    local lookup = app_icons[app]
    local icon = (lookup and lookup or app_icons["Default"])
    return icon
end

local function rerender_media()
    if state.enabled and state.current_app then
        local artist = state.artist
        local title = state.title
        local label = ""
        if artist ~= nil and title ~= nil then
            label = string.format("%s - %s", artist, title)
        elseif artist ~= nil then
            label = artist
        elseif title ~= nil then
            label = title
        end

        sbar.animate("tanh", 10, function()
            M.last_track_button:set { icon = { string = "" } }
            M.play_button:set { icon = { string = state.playing and "" or "" } }
            M.next_track_button:set { icon = { string = "" } }
            M.item:set {
                icon = {
                    string = get_app_icon(state.current_app),
                    color = whitelist[state.current_app],
                },
                label = { string = label },
            }
        end)
    else
        sbar.animate("tanh", 10, function()
            M.last_track_button:set { icon = { string = "" } }
            M.play_button:set { icon = { string = "" } }
            M.next_track_button:set { icon = { string = "" } }
            M.item:set { icon = { string = "" }, label = { string = "" } }
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

---@param seconds number
local function scroll(seconds)
    sbar.exec(string.format("~/.config/sketchybar/items/scroll_media_title.sh %d &", seconds))
end

function M.setup(opts)
    opts = opts or {}

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
            scroll_duration = 200,
        },
        position = "center",
        scroll_texts = false,
        padding_left = 8,
    })

    M.last_track_button = last_track_button
    M.play_button = play_button
    M.next_track_button = next_track_button
    M.item = media

    play_button:subscribe("mouse.clicked", play_pause)
    last_track_button:subscribe("mouse.clicked", last_track)
    next_track_button:subscribe("mouse.clicked", next_track)

    media:subscribe("mouse.clicked", function(env)
        if env.BUTTON == "left" then
            play_pause()
            scroll(5)
        elseif env.BUTTON == "right" then
            toggle_app()
        end
    end)

    media:subscribe("media_change", function(env)
        local app_color = whitelist[env.INFO.app]
        if app_color ~= nil then
            state.current_app = env.INFO.app
            state.artist = (env.INFO.artist ~= "" and env.INFO.artist) or nil
            state.title = (env.INFO.title ~= "" and env.INFO.title) or nil
            state.playing = env.INFO.state == "playing"
            rerender_media()
            scroll(5)
        end
    end)

    media:subscribe("media_toggle", function(_)
        state.enabled = not state.enabled
        rerender_media()
        scroll(5)
    end)

    media:subscribe("media_scroll_start", function(_)
        M.item:set { scroll_texts = true }
    end)

    media:subscribe("media_scroll_stop", function(_)
        M.item:set { scroll_texts = false }
    end)
end

return M
