#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:$PATH"

window_id=$1
current_space_index=$(yabai -m query --spaces --space | jq -r '.index')
yabai -m window "$window_id" --space "$current_space_index"
