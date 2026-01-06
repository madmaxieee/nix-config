#!/usr/bin/env bash

PATH="/run/current-system/sw/bin:$PATH"
PATH="/opt/homebrew/bin:$PATH"

# using hammerspoon here because sometimes aerospace list-windows returns the wrong focused window
focused_win_id="$(hs -c 'hs.window.focusedWindow():id()')"
current_space_win_ids="$(aerospace list-windows --workspace focused --format '%{window-id}')"

if ! echo "$current_space_win_ids" | grep -q "^$focused_win_id$"; then
  first_win_id="$(echo "$current_space_win_ids" | head -n 1)"
  if [ -n "$first_win_id" ]; then
    hs -c "hs.window.get($first_win_id):focus()"
  fi
fi
