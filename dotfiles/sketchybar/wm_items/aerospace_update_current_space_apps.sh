#!/usr/bin/env bash

visible_apps="$(aerospace list-apps --macos-native-hidden no --json |
  jq --compact-output '[ .[] | { key: ."app-name", value: true } ] | from_entries')"

current_space="$(cat /tmp/aerospace_current_space)"

json="$(aerospace list-windows --workspace "$current_space" --json | jq --compact-output '[ .[] | ."app-name" ]')"
sketchybar --trigger aerospace_update_space_apps SPACE="$current_space" APPS="$json" VISIBLE="$visible_apps" &
