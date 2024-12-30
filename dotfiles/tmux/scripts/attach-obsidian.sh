#! /usr/bin/env bash

if ! tmux has-session -t obsidian; then
	tmux new-session -d -c ~/obsidian/ -s obsidian nvim
fi
tmux set-option -t 'obsidian' detach-on-destroy on
tmux set-option -t 'obsidian' status off
tmux attach -t obsidian
