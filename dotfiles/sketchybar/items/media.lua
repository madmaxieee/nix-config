local sbar = require "sketchybar"
local colors = require "colors"
local app_icons = require "icon_map"

local M = {}

local app_colors = {
    ["Spotify"] = colors.green,
    ["Podcasts"] = colors.magenta,
}

local bundle_ids = {
    ["com.apple.podcasts"] = "Podcasts",
    ["com.spotify.client"] = "Spotify",
}

---@class MediaState
---@field enabled boolean
---@field current_app string?
---@field playing boolean?
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

        M.item:set {
            icon = {
                string = get_app_icon(state.current_app),
                color = app_colors[state.current_app],
            },
        }
        sbar.animate("tanh", 10, function()
            M.last_track_button:set { icon = { string = "" } }
            if state.playing == nil then
                M.play_button:set { icon = { string = "" } }
            else
                M.play_button:set { icon = { string = state.playing and "" or "" } }
            end
            M.next_track_button:set { icon = { string = "" } }
            M.item:set { label = { string = label } }
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

    sbar.exec "~/.config/sketchybar/items/media_control_stream.sh"
    media:subscribe("media_control_stream", function(env)
        local app = bundle_ids[env.INFO.bundleIdentifier]
        if app ~= nil then
            state.current_app = app
            state.artist = (env.INFO.artist ~= "" and env.INFO.artist) or nil
            state.title = (env.INFO.title ~= "" and env.INFO.title) or nil
            state.playing = env.INFO.playing
            rerender_media()
            scroll(5)
        end
    end)

    -- -- workaround for spotify that detects pause/play state
    -- sbar.add("event", "spotify_change", "com.spotify.client.PlaybackStateChanged")
    -- media:subscribe("spotify_change", function(env)
    --     state.current_app = "Spotify"
    --     state.artist = (env.INFO.Artist ~= "" and env.INFO.Artist) or nil
    --     state.title = (env.INFO.Name ~= "" and env.INFO.Name) or nil
    --     state.playing = env.INFO["Player State"] == "Playing"
    --     rerender_media()
    --     scroll(5)
    -- end)

    -- -- incomplete solution I wrote, can't detect pause/play state
    -- sbar.exec "~/.config/sketchybar/items/my_media_change.sh"
    -- media:subscribe("my_media_change", function(env)
    --     local app_color = app_colors[env.INFO.app]
    --     if app_color ~= nil then
    --         state.current_app = env.INFO.app
    --         state.artist = (env.INFO.artist ~= "" and env.INFO.artist) or nil
    --         state.title = (env.INFO.title ~= "" and env.INFO.title) or nil
    --         if env.INFO.app ~= "Spotify" then
    --             if env.INFO.state == nil then
    --                 state.playing = nil
    --             elseif env.INFO.state == "playing" then
    --                 state.playing = true
    --             else
    --                 state.playing = false
    --             end
    --         end
    --         rerender_media()
    --         scroll(5)
    --     end
    -- end)

    -- -- media_change is broken on macOS > 15.4
    -- media:subscribe("media_change", function(env)
    --     local app_color = app_colors[env.INFO.app]
    --     if app_color ~= nil then
    --         state.current_app = env.INFO.app
    --         state.artist = (env.INFO.artist ~= "" and env.INFO.artist) or nil
    --         state.title = (env.INFO.title ~= "" and env.INFO.title) or nil
    --         state.playing = env.INFO.state == "playing"
    --         rerender_media()
    --         scroll(5)
    --     end
    -- end)

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
