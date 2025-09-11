#!/usr/bin/env bash

pkill -f "netstat -w5"
netstat -w5 |
  awk '/[0-9]/ {print $3/5 "," $6/5; fflush(stdout)}' |
  while IFS="," read -r down up; do
    sketchybar --trigger netstat_update "DOWNLOAD=$down" "UPLOAD=$up"
  done
