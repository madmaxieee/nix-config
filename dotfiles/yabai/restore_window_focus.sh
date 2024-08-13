#!/usr/bin/env bash
# focus a space while ignoring Arc PIP windows

PATH="/run/current-system/sw/bin:$PATH"

current_space=$(yabai -m query --spaces | jq '[ .[] | select(."has-focus")][0].id')

~/.config/yabai/focus_window_in_space.sh "$current_space" || exit 1
