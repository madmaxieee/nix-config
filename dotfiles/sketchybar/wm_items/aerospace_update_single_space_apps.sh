#!/usr/bin/env bash

space="$1"

visible_apps="$(aerospace list-apps --macos-native-hidden no --json |
  jq --compact-output '[ .[] | { key: ."app-name", value: true } ] | from_entries')"

json="$(aerospace list-windows --workspace "$space" --json |
  jq --compact-output '[ .[] | select(."window-title" != "Picture in Picture") | ."app-name" ]')"
sketchybar --trigger aerospace_update_space_apps SPACE="$space" APPS="$json" VISIBLE="$visible_apps"
