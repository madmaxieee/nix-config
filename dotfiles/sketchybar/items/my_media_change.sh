#!/usr/bin/env bash

# run the osascript located in the same directory as this script
osascript_path="$(dirname "$0")/my_media_change.scpt"

pkill -f "$osascript_path"

osascript "$osascript_path" 2>&1 | while IFS= read -r line; do
  bash -c "sketchybar --trigger my_media_change INFO=$(printf %q "$line")"
done
