#! /usr/bin/env bash

if [[ "$(tmux show-options detach-on-destroy)" == "detach-on-destroy on" ]]; then
  exit 0
fi

tmux new-session -d -s main -c "$HOME" >/dev/null 2>&1

if which starship &>/dev/null; then
  hostname_module="$(starship module hostname | cut -d' ' -f1) "
else
  hostname_module=''
fi

border_label=" sesh $hostname_module"
prompt_prefix="$hostname_module"

session="$(
  sesh list --icons | grep -v '__popup$' | fzf-tmux -p 55%,60% \
    --no-sort --ansi --border-label "$border_label" --prompt "$prompt_prefix"'⚡  ' \
    --header ' ^r reload ^a all ^t tmux ^g configs ^x zoxide ^d kill ^f find' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-r:change-prompt('"$prompt_prefix"'⚡  )+reload(sesh list --icons | grep -v __popup\$)' \
    --bind 'ctrl-a:change-prompt('"$prompt_prefix"'⚡  )+reload(sesh list --icons)' \
    --bind 'ctrl-t:change-prompt('"$prompt_prefix"'🪟  )+reload(sesh list --icons --tmux | grep -v __popup\$)' \
    --bind 'ctrl-g:change-prompt('"$prompt_prefix"'⚙️  )+reload(sesh list --icons --config)' \
    --bind 'ctrl-x:change-prompt('"$prompt_prefix"'📁  )+reload(sesh list --icons --zoxide)' \
    --bind 'ctrl-f:change-prompt('"$prompt_prefix"'🔎  )+reload(fd -H -d 2 -t d -E .Trash -E .cache . ~)' \
    --bind 'ctrl-d:execute(echo {} | cut -d" " -f2 | xargs tmux kill-session -t)+reload(sesh list --icons | grep -v __popup\$)' \
    --bind 'ctrl-alt-k:abort'
)"

# strip the icon from the session name
session="${session#* }"

tmux set-option -t "$session" detach-on-destroy off &
tmux set-option -t "$session" status on &
sesh connect "$session"
