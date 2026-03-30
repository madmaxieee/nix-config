#!/usr/bin/env bash

if [[ "$(tmux show-options detach-on-destroy)" == "detach-on-destroy on" ]]; then
  exit 0
fi

tmux new-session -d -s main -c "$HOME" >/dev/null 2>&1

if command -v starship &>/dev/null; then
  hostname_module="$(starship module hostname | sed 's/\x1b\[[0-9;]*[a-mGKH]//g')"
  hostname_module="${hostname_module%% *}"
else
  hostname_module=''
fi

if [[ -n "$hostname_module" ]]; then
  hostname_module=" $hostname_module"
fi

input_header="sesh$hostname_module"
prompt_prefix="$hostname_module"

session=$(
  tv-tmux -p 55%,60% -- \
    --no-status-bar \
    --input-header "$input_header" \
    --input-prompt "$prompt_prefix >" \
    --cable-dir ~/nix-config/dotfiles/tmux/cables \
    --no-sort \
    sesh
)

if [[ -z "$session" ]]; then
  exit 0
fi

if [[ "$session" == " [cloud] "* ]]; then
  stripped_session=$(echo "$session" | cut -d' ' -f3-)
  if tmux has-session -t cloud 2>/dev/null; then
    tmux send-keys -t cloud C-space :
    tmux send-keys -t cloud "attach -t $stripped_session" Enter &
  fi
  sesh connect cloud
elif [[ "$session" == "󰌪 "* ]]; then
  stripped_session="${session#* }"
  session_name="${stripped_session//[.:]/_}"
  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "/google/src/cloud/$LOGNAME/$stripped_session"
  fi
  tmux set-option -t "$session_name" detach-on-destroy off 2>/dev/null &
  tmux set-option -t "$session_name" status on 2>/dev/null &
  sesh connect "$session_name"
else
  stripped_session="${session#* }"
  tmux set-option -t "$stripped_session" detach-on-destroy off 2>/dev/null &
  tmux set-option -t "$stripped_session" status on 2>/dev/null &
  sesh connect "$stripped_session"
fi
