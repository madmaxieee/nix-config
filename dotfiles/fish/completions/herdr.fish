# Basic fish completions for herdr.

function __fish_herdr_needs_command
    set -l cmd (commandline -opc)
    set -e cmd[1]

    for token in $cmd
        switch $token
            case '-*'
                continue
            case '*'
                return 1
        end
    end

    return 0
end

function __fish_herdr_using_command
    set -l cmd (commandline -opc)
    contains -- $argv[1] $cmd
end

complete -c herdr -f

complete -c herdr -n __fish_herdr_needs_command -l no-session -d 'Run without server/client session'
complete -c herdr -n __fish_herdr_needs_command -l session -r -d 'Use or create a named session'
complete -c herdr -n __fish_herdr_needs_command -l remote -r -d 'Attach through SSH to a remote Herdr server'
complete -c herdr -n __fish_herdr_needs_command -l remote-keybindings -xa 'local server' -d 'Choose keybindings for remote attach'
complete -c herdr -n __fish_herdr_needs_command -l handoff -d 'Opt into live handoff'
complete -c herdr -n __fish_herdr_needs_command -l default-config -d 'Print default configuration'
complete -c herdr -n __fish_herdr_needs_command -s V -l version -d 'Print version'
complete -c herdr -n __fish_herdr_needs_command -s h -l help -d 'Show help'

complete -c herdr -n __fish_herdr_needs_command -a status -d 'Show client and server status'
complete -c herdr -n __fish_herdr_needs_command -a update -d 'Download and install the latest version'
complete -c herdr -n __fish_herdr_needs_command -a server -d 'Server commands'
complete -c herdr -n __fish_herdr_needs_command -a config -d 'Config commands'
complete -c herdr -n __fish_herdr_needs_command -a channel -d 'Manage update channel'
complete -c herdr -n __fish_herdr_needs_command -a workspace -d 'Workspace helpers'
complete -c herdr -n __fish_herdr_needs_command -a worktree -d 'Git worktree helpers'
complete -c herdr -n __fish_herdr_needs_command -a tab -d 'Tab helpers'
complete -c herdr -n __fish_herdr_needs_command -a notification -d 'Notification helpers'
complete -c herdr -n __fish_herdr_needs_command -a agent -d 'Agent helpers'
complete -c herdr -n __fish_herdr_needs_command -a pane -d 'Pane control helpers'
complete -c herdr -n __fish_herdr_needs_command -a wait -d 'Blocking wait helpers'
complete -c herdr -n __fish_herdr_needs_command -a session -d 'Manage named sessions'
complete -c herdr -n __fish_herdr_needs_command -a integration -d 'Manage built-in integrations'

complete -c herdr -n '__fish_herdr_using_command status' -a 'server client'
complete -c herdr -n '__fish_herdr_using_command server' -a 'stop reload-config'
complete -c herdr -n '__fish_herdr_using_command config' -a reset-keys
complete -c herdr -n '__fish_herdr_using_command channel' -a set
complete -c herdr -n '__fish_herdr_using_command channel; and __fish_seen_subcommand_from set' -a 'stable preview'
complete -c herdr -n '__fish_herdr_using_command session' -a attach
