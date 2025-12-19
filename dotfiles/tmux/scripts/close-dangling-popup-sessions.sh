#!/usr/bin/env bash

tmux list-sessions -F '#S' |
  ~/.config/tmux/scripts/filter_dangling_popup_sessions.py |
  xargs -I {} tmux kill-session -t {}
