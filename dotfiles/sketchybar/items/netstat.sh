#!/usr/bin/env bash

pkill -f "netstat -w5"
netstat -w5 \
  | awk 'NR > 2 {print "{download=" $3/5 ", upload=" $6/5 "}"; fflush(stdout) }' \
  | xargs -I {} sketchybar --trigger netstat_update INFO={} &
