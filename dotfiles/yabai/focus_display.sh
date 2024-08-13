#!/usr/bin/env bash
# focusing display in direction while ignoring Arc PIP windows

PATH="/run/current-system/sw/bin:$PATH"

direction=$1

visible_space_index=$(yabai -m query --spaces --display "$direction" | jq '.[] | select(.["is-visible"]==true) | .index')

~/.config/yabai/focus_window_in_space.sh "$visible_space_index" || yabai -m display --focus "$direction"
