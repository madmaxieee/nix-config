#!/usr/bin/env bash

seconds="$1"

sketchybar --trigger media_scroll_start
sleep "$seconds"
sketchybar --trigger media_scroll_stop
