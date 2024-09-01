#!/usr/bin/env bash
# focus a space while ignoring Arc PIP windows

PATH="/run/current-system/sw/bin:$PATH"

space_index=$1

# if any window other than Arc PIP and PastePal has focus
space_has_focus=$(yabai -m query --windows --space "$space_index" \
    | jq '[ .[] | select((.app == "Arc" or .app == "PastePal") and .["is-floating"] | not) ] | map(.["has-focus"]) | any')

if [[ "$space_has_focus" = "false" ]]; then
    first_window_id="null"
    # the first window in the space that is not Arc PIP
    first_window_id=$(yabai -m query --windows --space "$space_index" \
        | jq '[ .[] | select((.app == "Arc" or .app == "PastePal") and .["is-floating"] | not) ].[0].id')

    if [[ "$first_window_id" != "null" ]]; then
        yabai -m window --focus "$first_window_id"
    else
        exit 1
    fi
else
    exit 1
fi
