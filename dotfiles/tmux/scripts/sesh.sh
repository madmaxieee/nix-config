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

cloudtop_session_prefix='☁️[cloud] '
# remote sesh service over ssh tunnel
cloudtop_session_command="curl localhost:8080/sesh/tmux | awk '!/__popup\$/ { print \"$cloudtop_session_prefix\" \$0 }'"

session="$(
  {
    sesh list --icons --tmux
    sesh list --icons --config
    curl localhost:8080/sesh/tmux | awk '{ print "'"$cloudtop_session_prefix"'" $0 }'
    sesh list --icons --zoxide
  } | grep -v '__popup$' | fzf-tmux -p 55%,60% \
    --no-sort --ansi --border-label "$border_label" --prompt "$prompt_prefix"'⚡  ' \
    --header ' ^r reload ^a all ^t tmux ^g configs ^x zoxide ^d kill ^f find' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-r:change-prompt('"$prompt_prefix"'⚡  )+reload(sesh list --icons | grep -v __popup\$)' \
    --bind 'ctrl-a:change-prompt('"$prompt_prefix"'⚡  )+reload(sesh list --icons)' \
    --bind 'ctrl-t:change-prompt('"$prompt_prefix"'🪟  )+reload(sesh list --icons --tmux | grep -v __popup\$)' \
    --bind 'ctrl-g:change-prompt('"$prompt_prefix"'⚙️  )+reload(sesh list --icons --config)' \
    --bind 'ctrl-x:change-prompt('"$prompt_prefix"'📁  )+reload(sesh list --icons --zoxide)' \
    --bind 'ctrl-f:change-prompt('"$prompt_prefix"'🔎  )+reload(fd -H -d 2 -t d -E .Trash -E .cache . ~)' \
    --bind 'ctrl-s:change-prompt('"$prompt_prefix"'☁️  )+reload('"$cloudtop_session_command"')' \
    --bind 'ctrl-d:execute(echo {} | cut -d" " -f2 | xargs tmux kill-session -t)+reload(sesh list --icons | grep -v __popup\$)' \
    --bind 'ctrl-alt-k:abort'
)"

stripped_session="${session#* }"

if [[ $session == "$cloudtop_session_prefix"* ]]; then
  tmux send-keys -t cloud C-space ':'
  tmux send-keys -t cloud "attach -t $stripped_session" C-m &
  sesh connect cloud
else
  tmux set-option -t "$stripped_session" detach-on-destroy off 2>/dev/null &
  tmux set-option -t "$stripped_session" status on 2>/dev/null &
  sesh connect "$stripped_session"
fi
