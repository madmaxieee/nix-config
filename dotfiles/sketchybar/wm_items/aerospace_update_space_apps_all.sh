#!/usr/bin/env bash

visible_apps="$(aerospace list-apps --macos-native-hidden no --json |
  jq --compact-output '[ .[] | { key: ."app-name", value: true } ] | from_entries')"

aerospace list-workspaces --all | while read -r space; do
  json="$(aerospace list-windows --workspace "$space" --json | jq --compact-output '[ .[] | ."app-name" ]')"
  sketchybar --trigger aerospace_update_space_apps SPACE="$space" APPS="$json" VISIBLE="$visible_apps" &
done
