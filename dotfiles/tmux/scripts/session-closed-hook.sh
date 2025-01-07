#! /usr/bin/env bash

~/.config/tmux/scripts/close-dangling-popup-sessions.sh

SESSION="$(tmux display-message -p '#S')"

if [[ "$SESSION" =~ .__popup$ || "$SESSION" == obsidian ]]; then
  tmux new-session -d -s main -c "$HOME" >/dev/null 2>&1
  tmux switch-client -t main
  ~/.config/tmux/scripts/sesh.sh
fi
