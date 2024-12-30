#! /usr/bin/env bash
session="$1"

client_height=$(tmux display-message -p '#{client_height}')
client_width=$(tmux display-message -p '#{client_width}')

popup_height=$(echo "scale=0; $client_height * 0.8 / 1" | bc)
popup_width=$(echo "scale=0; $client_width * 0.8 / 1" | bc)

tmux display-popup -h "$popup_height" -w "$popup_width" -E "tmux attach -t $session"
