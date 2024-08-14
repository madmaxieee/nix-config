#! /usr/bin/env bash
command="$1"

client_height=$(tmux display-message -p '#{client_height}')
client_width=$(tmux display-message -p '#{client_width}')

popup_height=$(bc -e "scale=0; $client_height * 0.8 / 1")
popup_width=$(bc -e "scale=0; $client_width * 0.8 / 1")

tmux display-popup -h "$popup_height" -w "$popup_width" -E "$command"
