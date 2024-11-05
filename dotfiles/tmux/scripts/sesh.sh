#! /usr/bin/env bash

if tmux display-message -p "#S" | grep -q -E ".__popup$"; then
	exit 0
fi

tmux new-session -d -s main -c "$HOME" > /dev/null 2>&1 

if which starship &> /dev/null; then
	border_label=" sesh $(starship module hostname | cut -d' ' -f1) "
else
	border_label=' sesh '
fi

session="$(
 sesh list | grep -v -E '.__popup$' | fzf-tmux -p 55%,60% \
		--no-sort --border-label "$border_label" --prompt '⚡  ' \
		--header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
		--bind 'tab:down,btab:up' \
		--bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
		--bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
		--bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
		--bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
		--bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash -E .cache . ~)' \
		--bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)' \
		--bind 'ctrl-alt-k:abort'
)"

sesh connect "$session"
