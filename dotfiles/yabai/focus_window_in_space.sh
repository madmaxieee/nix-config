#!/usr/bin/env bash
# focus a space while ignoring sticky windows

PATH="/run/current-system/sw/bin:$PATH"

space_index=$1

# if any non sticky window has focus
space_has_focus=$(yabai -m query --windows --space "$space_index" |
    jq '[ .[] | select(."is-sticky" | not) ] | map(.["has-focus"]) | any')

echo space_has_focus "$space_has_focus"

if [[ "$space_has_focus" = "false" ]]; then
    first_window_id="null"
    # the first window in the space that is not sticky
    first_window_id=$(yabai -m query --windows --space "$space_index" |
        jq '[ .[] | select(."is-sticky" | not) ].[0].id')

    echo first_window_id "$first_window_id"

    if [[ "$first_window_id" != "null" ]]; then
        yabai -m window --focus "$first_window_id"
    else
        exit 1
    fi
else
    exit 1
fi
