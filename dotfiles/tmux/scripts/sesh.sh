#!/usr/bin/env bash

if [[ "$(tmux show-options detach-on-destroy)" == "detach-on-destroy on" ]]; then
  exit 0
fi

tmux new-session -d -s main -c "$HOME" >/dev/null 2>&1

if command -v starship &>/dev/null; then
  hostname_module="$(starship module hostname | cut -d' ' -f1) "
else
  hostname_module=''
fi

input_header=" sesh$hostname_module"
prompt_prefix="$hostname_module"

cloudtop_session_prefix='☁️[cloud] '

session=$(
  tv-tmux -p 55%,60% -- \
    --no-status-bar \
    --input-header "$input_header" \
    --input-prompt "$prompt_prefix>" \
    --cable-dir ~/nix-config/dotfiles/tmux/cables \
    sesh
)

if [[ -z "$session" ]]; then
  exit 0
fi

stripped_session="${session#* }"

if [[ $session == "$cloudtop_session_prefix"* ]]; then
  tmux send-keys -t cloud C-space ':'
  tmux send-keys -t cloud "attach -t $stripped_session" C-m &
  sesh connect cloud
else
  tmux set-option -t "$stripped_session" detach-on-destroy off 2>/dev/null &
  tmux set-option -t "$stripped_session" status on 2>/dev/null &
  sesh connect "$stripped_session"
fi
