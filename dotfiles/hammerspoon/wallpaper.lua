local function is_in_screen(screen, win)
    return win:screen() == screen
end

local function focusScreen(screen)
    -- Get windows within screen, ordered from front to back.
    -- If no windows exist, bring focus to desktop. Otherwise, set focus on
    -- front-most application window.
    local windows = hs.fnutils.filter(hs.window.orderedWindows(), hs.fnutils.partial(is_in_screen, screen))
    local windowToFocus = #windows > 0 and windows[1] or hs.window.desktop()
    windowToFocus:focus()

    -- Move mouse to center of screen
    local pt = hs.geometry.rectMidPoint(screen:fullFrame())
    hs.mouse.absolutePosition(pt)
end

local function set_wallpaper(path)
    local spaces_table = hs.spaces.allSpaces()

    local url = hs.fs.urlFromPath(path)

    local screen_table = {}

    for _, screen in pairs(hs.screen.allScreens()) do
        screen_table[screen:getUUID()] = screen
    end

    for i, spaces in pairs(spaces_table) do
        local screen = screen_table[i]
        focusScreen(screen)
        for space in pairs(spaces) do
            hs.spaces.gotoSpace(space)
            hs.timer.usleep(300 * 1000)
            screen:desktopImageURL(url)
            hs.timer.usleep(300 * 1000)
        end
    end
end

return set_wallpaper
