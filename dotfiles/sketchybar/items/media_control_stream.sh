#!/usr/bin/env bash

pkill -f media-control

# wait until sketchybar is ready so we don't miss any events
sleep 1

media-control stream --no-diff | uniq |
  jq --compact-output --unbuffered '.payload | {artist, title, album, bundleIdentifier, playing}' |
  while IFS= read -r line; do
    sketchybar --trigger media_control_stream "INFO=$line"
  done
