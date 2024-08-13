#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:$PATH"

yabai -m space --create mouse
last_space=$(yabai -m query --spaces --display | jq 'map(select(."is-native-fullscreen" == false))[-1].index')
yabai -m space --focus "$last_space"
