#! /usr/bin/env bash

file=$(mktemp).sh
echo "#shellcheck disable=all" > "$file"
tmux capture-pane -pS -32768 >> "$file"
tmux split-window bash -c "TMUX_SCROLLBACK=1 nvim '+ normal G' $file"
tmux resize-pane -Z
