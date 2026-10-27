#!/usr/bin/env bash

set -euo pipefail

PATH="/run/current-system/sw/bin:$PATH"

window_id="$1"

current_space="$(aerospace list-workspaces --focused)"

aerospace move-node-to-workspace --window-id "$window_id" "$current_space"
