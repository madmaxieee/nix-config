#!/usr/bin/env hs

---@diagnostic disable-next-line: undefined-global
local win_id_str = _cli.args[2]
if not win_id_str then
	return
end

local ok, win_id = pcall(tonumber, win_id_str)
if not ok or not win_id then
	return
end

local win = hs.window.get(win_id)

-- wait for the window to be brought into frame by aerospace
hs.timer.usleep(100 * 1000)

local screen = hs.screen.mainScreen()

local win_frame = win:frame()
local screen_frame = screen:frame()

-- is win_frame intersecting with screen_frame?
-- if yes, then it's already in the right place, no need to center it
if
	win_frame.x < screen_frame.x + screen_frame.w
	and win_frame.x + win_frame.w > screen_frame.x
	and win_frame.y < screen_frame.y + screen_frame.h
	and win_frame.y + win_frame.h > screen_frame.y
then
	return
end

-- make sure the window is focused before centering
local focused_win = hs.application.frontmostApplication():focusedWindow()
if not focused_win or focused_win:id() ~= win_id then
	return
end

-- don't move managed windows
local is_managed = require("wm").is_managed
if is_managed(win_id) then
	return
end

TryCenterWindow(win)
