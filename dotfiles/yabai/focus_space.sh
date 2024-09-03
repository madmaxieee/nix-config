#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:$PATH"

SPACE_SEL="$1"

~/.config/yabai/focus_window_in_space.sh "$SPACE_SEL" && exit
yabai -m space --focus "$SPACE_SEL" > /dev/null 2>&1 && exit
yabai -m query --spaces --space "$SPACE_SEL" | jq -e '."has-focus"' && exit

# the previous command would fail with sip enabled
# if that's the case use hammerspoon to focus space instead
if [ -f /opt/homebrew/bin/hs ]; then
    SPACE_ID=$(yabai -m query --spaces --space "$SPACE_SEL" | jq '.id')
    /opt/homebrew/bin/hs -c "hs.alert('switching space')"
    /opt/homebrew/bin/hs -c "hs.spaces.gotoSpace($SPACE_ID)" > /dev/null 2>&1
fi
