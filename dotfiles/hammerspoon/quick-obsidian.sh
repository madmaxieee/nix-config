#!/usr/bin/env bash

set -euo pipefail

if ! tmux has-session -t obsidian 2>/dev/null; then
  tmux new-session -d -s obsidian -c ~/obsidian/ -s obsidian nvim '+Obsidian today'
fi
tmux set-option -t obsidian detach-on-destroy on
tmux set-option -t obsidian status off
exec tmux attach -t obsidian
