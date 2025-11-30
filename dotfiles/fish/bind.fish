status is-interactive || exit 0

fish_vi_key_bindings
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_visual underscore

# exit to normal mode with kj
bind -M insert -m default kj backward-char force-repaint
bind -M insert kk 'commandline -i k'

# control + l
bind \cl -M default 'flush; commandline -f repaint'
bind \cl -M insert 'flush; commandline -f repaint'

bind shift-up 'cd ..; commandline -f repaint'
bind shift-left 'prevd; commandline -f repaint'
bind shift-right 'nextd; commandline -f repaint'
bind shift-up -M insert 'cd ..; commandline -f repaint'
bind shift-left -M insert 'prevd; commandline -f repaint'
bind shift-right -M insert 'nextd; commandline -f repaint'

# unbind some keys
bind \ev true
bind \ev -M insert true
