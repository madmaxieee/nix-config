#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:$PATH"

window_id="$1"

current_space="$(cat /tmp/aerospace_current_space)"

aerospace move-node-to-workspace --window-id "$window_id" "$current_space"
