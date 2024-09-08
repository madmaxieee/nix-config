#!/usr/bin/env bash

pkill netstat -w1
netstat -w1 \
  | awk 'NR > 3 && NR%3==0 {print "{upload=" $3 ",download=" $6 "}"; fflush(stdout) }' \
  | xargs -I {} sketchybar --trigger netstat_update INFO={} &
