#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:$PATH"

yabai -m space --create mouse
last_space=$(yabai -m query --spaces --display | jq 'map(select(."is-native-fullscreen" == false))[-1].index')
~/.config/yabai/focus_space.sh "$last_space"
