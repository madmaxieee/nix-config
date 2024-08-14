status is-interactive || exit 0

# control + l
bind \cl -M default 'flush; commandline -f repaint'
bind \cl -M insert 'flush; commandline -f repaint'

bind -k sr 'cd ..; commandline -f repaint'
bind -k sleft 'prevd; commandline -f repaint'
bind -k sright 'nextd; commandline -f repaint'
bind -k sr -M insert 'cd ..; commandline -f repaint'
bind -k sleft -M insert 'prevd; commandline -f repaint'
bind -k sright -M insert 'nextd; commandline -f repaint'

# unbind some keys
bind \ev true
bind \ev -M insert true
