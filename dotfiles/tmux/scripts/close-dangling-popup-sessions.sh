#! /usr/bin/env bash

tmux ls |
  ~/.config/tmux/scripts/filter-dangling-popup-sessions.py |
  xargs -I {} tmux kill-session -t {}
