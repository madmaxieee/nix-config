#!/usr/bin/env bash

json=""

while read -r monitor; do
  spaces="$(aerospace list-workspaces --monitor "$monitor" --json | jq --compact-output '[ .[] | .workspace ]')"
  json="$json$spaces,"
done < <(aerospace list-monitors --format '%{monitor-id}')

json="[${json%,}]"

json=$(echo "$json" | jq --compact-output)

sketchybar --trigger aerospace_update_monitor_spaces DATA="$json"
