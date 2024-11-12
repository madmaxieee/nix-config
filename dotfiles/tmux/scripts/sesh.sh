#! /usr/bin/env bash

if tmux display-message -p "#S" | grep -q -E ".__popup$"; then
	exit 0
fi

tmux new-session -d -s main -c "$HOME" > /dev/null 2>&1 

if which starship &> /dev/null; then
	hostname_module="$(starship module hostname | cut -d' ' -f1) "
else
	hostname_module=''
fi

border_label=" sesh $hostname_module"
prompt_prefix="$hostname_module"

session="$(
 sesh list | grep -v -E '.__popup$' | fzf-tmux -p 55%,60% \
		--no-sort --border-label "$border_label" --prompt "$prompt_prefix"'⚡  ' \
		--header '  ^a all ^t tmux ^g configs ^x zoxide ^d kill ^f find' \
		--bind 'tab:down,btab:up' \
		--bind 'ctrl-a:change-prompt('"$prompt_prefix"'⚡  )+reload(sesh list)' \
		--bind 'ctrl-t:change-prompt('"$prompt_prefix"'🪟  )+reload(sesh list -t)' \
		--bind 'ctrl-g:change-prompt('"$prompt_prefix"'⚙️  )+reload(sesh list -c)' \
		--bind 'ctrl-x:change-prompt('"$prompt_prefix"'📁  )+reload(sesh list -z)' \
		--bind 'ctrl-f:change-prompt('"$prompt_prefix"'🔎  )+reload(fd -H -d 2 -t d -E .Trash -E .cache . ~)' \
		--bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)' \
		--bind 'ctrl-alt-k:abort'
)"

sesh connect "$session"
