#!/usr/bin/env bash

pkill -f media-control

media-control stream --no-diff | uniq |
  jq --compact-output --unbuffered '.payload | {artist: .artist, title: .title, album: .album, bundleIdentifier: .bundleIdentifier, playing: .playing}' | while IFS= read -r line; do
  bash -c "sketchybar --trigger media_control_stream INFO=$(printf %q "$line")"
done
