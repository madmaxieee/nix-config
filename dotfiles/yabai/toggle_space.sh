#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:$PATH"

target_space_index="$1"

tmp_file="/tmp/skhd_space_toggle_$target_space_index"

current_space_index=$(yabai -m query --spaces --space | jq -r '.index')

if [ -f "$tmp_file" ]; then
    previous_space_index=$(cat "$tmp_file")
else
    previous_space_index="$current_space_index"
fi

if [ "$current_space_index" = "$target_space_index" ]; then
    ~/.config/yabai/focus_space.sh "$previous_space_index"
else
    echo "$current_space_index" > "$tmp_file"
    ~/.config/yabai/focus_space.sh "$target_space_index"
fi
