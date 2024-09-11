#! /usr/bin/env bash

tmux list-sessions -F '#S' |
  ~/.config/tmux/scripts/filter-dangling-popup-sessions.py |
  xargs -I {} tmux kill-session -t {}
