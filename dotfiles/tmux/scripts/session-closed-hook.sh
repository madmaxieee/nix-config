#! /usr/bin/env bash

~/.config/tmux/scripts/close-dangling-popup-sessions.sh

# if attached to a popup session after session is closed, attach to main instead
# popup sessions are only supposed to be attached to popup windows
if [[ "$(tmux display-message -p "#S")" =~ .__popup$ ]] && [[ "$(tmux show-options detach-on-destroy)" != "detach-on-destroy on" ]]; then
	tmux new-session -d -s main -c "$HOME" > /dev/null 2>&1
	tmux switch-client -t main
	~/.config/tmux/scripts/sesh.sh
fi
