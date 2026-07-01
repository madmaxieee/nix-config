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

function __fish_herdr_subcommand
    set -l cmd (commandline -opc)
    set -e cmd[1]
    set -l subcmds
    for token in $cmd
        switch $token
            case '-*'
                continue
            case '*'
                set -a subcmds $token
        end
    end
    test (count $subcmds) -eq (count $argv)
    and test "$subcmds" = "$argv"
end

complete -c herdr -f

# Global options
complete -c herdr -n __fish_herdr_needs_command -l no-session -d 'Run without server/client session'
complete -c herdr -n __fish_herdr_needs_command -l session -r -d 'Use or create a named session'
complete -c herdr -n __fish_herdr_needs_command -l remote -r -d 'Attach through SSH to a remote Herdr server'
complete -c herdr -n __fish_herdr_needs_command -l remote-keybindings -xa 'local server' -d 'Choose keybindings for remote attach'
complete -c herdr -n __fish_herdr_needs_command -l handoff -d 'Opt into live handoff'
complete -c herdr -n __fish_herdr_needs_command -l default-config -d 'Print default configuration'
complete -c herdr -n __fish_herdr_needs_command -s V -l version -d 'Print version'
complete -c herdr -n __fish_herdr_needs_command -s h -l help -d 'Show help'

# Top-level commands
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
complete -c herdr -n __fish_herdr_needs_command -a plugin -d 'Plugin commands'

# status
complete -c herdr -n '__fish_herdr_subcommand status' -a 'server client'
complete -c herdr -n '__fish_herdr_using_command status' -l json -d 'Output in JSON format'

# update
complete -c herdr -n '__fish_herdr_using_command update' -l handoff -d 'Opt into live handoff'

# server
complete -c herdr -n '__fish_herdr_subcommand server' -a 'stop live-handoff reload-config agent-manifests update-agent-manifests reload-agent-manifests'
complete -c herdr -n '__fish_herdr_subcommand server agent-manifests' -l json -d 'Output in JSON format'
complete -c herdr -n '__fish_herdr_subcommand server update-agent-manifests' -l json -d 'Output in JSON format'

# config
complete -c herdr -n '__fish_herdr_subcommand config' -a reset-keys

# channel
complete -c herdr -n '__fish_herdr_subcommand channel' -a 'show set'
complete -c herdr -n '__fish_herdr_subcommand channel set' -a 'stable preview'

# workspace
complete -c herdr -n '__fish_herdr_subcommand workspace' -a 'list create get focus rename close'
complete -c herdr -n '__fish_herdr_subcommand workspace create' -l cwd -r -d 'Working directory'
complete -c herdr -n '__fish_herdr_subcommand workspace create' -l label -r -d 'Workspace label'
complete -c herdr -n '__fish_herdr_subcommand workspace create' -l env -r -d 'Environment variable (KEY=VALUE)'
complete -c herdr -n '__fish_herdr_subcommand workspace create' -l focus -d 'Focus newly created workspace'
complete -c herdr -n '__fish_herdr_subcommand workspace create' -l no-focus -d 'Do not focus newly created workspace'

# worktree
complete -c herdr -n '__fish_herdr_subcommand worktree' -a 'list create open remove'
complete -c herdr -n '__fish_herdr_subcommand worktree list' -l workspace -r -d 'Workspace ID'
complete -c herdr -n '__fish_herdr_subcommand worktree list' -l cwd -r -d 'Working directory'
complete -c herdr -n '__fish_herdr_subcommand worktree list' -l json -d 'Output in JSON format'
complete -c herdr -n '__fish_herdr_subcommand worktree create' -l workspace -r -d 'Workspace ID'
complete -c herdr -n '__fish_herdr_subcommand worktree create' -l cwd -r -d 'Working directory'
complete -c herdr -n '__fish_herdr_subcommand worktree create' -l branch -r -d 'Branch name'
complete -c herdr -n '__fish_herdr_subcommand worktree create' -l base -r -d 'Base git ref'
complete -c herdr -n '__fish_herdr_subcommand worktree create' -l path -r -d 'Worktree target path'
complete -c herdr -n '__fish_herdr_subcommand worktree create' -l label -r -d 'Worktree label'
complete -c herdr -n '__fish_herdr_subcommand worktree create' -l focus -d 'Focus created worktree'
complete -c herdr -n '__fish_herdr_subcommand worktree create' -l no-focus -d 'Do not focus created worktree'
complete -c herdr -n '__fish_herdr_subcommand worktree create' -l json -d 'Output in JSON format'
complete -c herdr -n '__fish_herdr_subcommand worktree open' -l workspace -r -d 'Workspace ID'
complete -c herdr -n '__fish_herdr_subcommand worktree open' -l cwd -r -d 'Working directory'
complete -c herdr -n '__fish_herdr_subcommand worktree open' -l path -r -d 'Path to open'
complete -c herdr -n '__fish_herdr_subcommand worktree open' -l branch -r -d 'Branch to open'
complete -c herdr -n '__fish_herdr_subcommand worktree open' -l label -r -d Label
complete -c herdr -n '__fish_herdr_subcommand worktree open' -l focus -d 'Focus opened worktree'
complete -c herdr -n '__fish_herdr_subcommand worktree open' -l no-focus -d 'Do not focus opened worktree'
complete -c herdr -n '__fish_herdr_subcommand worktree open' -l json -d 'Output in JSON format'
complete -c herdr -n '__fish_herdr_subcommand worktree remove' -l workspace -r -d 'Workspace ID'
complete -c herdr -n '__fish_herdr_subcommand worktree remove' -l force -d 'Force removal'
complete -c herdr -n '__fish_herdr_subcommand worktree remove' -l json -d 'Output in JSON format'

# tab
complete -c herdr -n '__fish_herdr_subcommand tab' -a 'list create get focus rename close'
complete -c herdr -n '__fish_herdr_subcommand tab list' -l workspace -r -d 'Workspace ID'
complete -c herdr -n '__fish_herdr_subcommand tab create' -l workspace -r -d 'Workspace ID'
complete -c herdr -n '__fish_herdr_subcommand tab create' -l cwd -r -d 'Working directory'
complete -c herdr -n '__fish_herdr_subcommand tab create' -l label -r -d 'Tab label'
complete -c herdr -n '__fish_herdr_subcommand tab create' -l env -r -d 'Environment variable'
complete -c herdr -n '__fish_herdr_subcommand tab create' -l focus -d 'Focus created tab'
complete -c herdr -n '__fish_herdr_subcommand tab create' -l no-focus -d 'Do not focus created tab'

# notification
complete -c herdr -n '__fish_herdr_subcommand notification' -a show
complete -c herdr -n '__fish_herdr_subcommand notification show' -l body -r -d 'Notification body'
complete -c herdr -n '__fish_herdr_subcommand notification show' -l position -xa 'top-left top-right bottom-left bottom-right' -d Position
complete -c herdr -n '__fish_herdr_subcommand notification show' -l sound -xa 'none done request' -d 'Sound effect'

# agent
complete -c herdr -n '__fish_herdr_subcommand agent' -a 'list get read send rename focus wait attach start explain'
complete -c herdr -n '__fish_herdr_subcommand agent read' -l source -xa 'visible recent recent-unwrapped' -d 'Read source'
complete -c herdr -n '__fish_herdr_subcommand agent read' -l lines -r -d 'Number of lines'
complete -c herdr -n '__fish_herdr_subcommand agent read' -l format -xa 'text ansi' -d 'Output format'
complete -c herdr -n '__fish_herdr_subcommand agent read' -l ansi -d 'Use ANSI format'
complete -c herdr -n '__fish_herdr_subcommand agent rename' -l clear -d 'Clear name'
complete -c herdr -n '__fish_herdr_subcommand agent wait' -l status -xa 'idle working blocked unknown' -d 'Status to wait for'
complete -c herdr -n '__fish_herdr_subcommand agent wait' -l timeout -r -d 'Timeout in ms'
complete -c herdr -n '__fish_herdr_subcommand agent attach' -l takeover -d 'Take over agent'
complete -c herdr -n '__fish_herdr_subcommand agent start' -l cwd -r -d 'Working directory'
complete -c herdr -n '__fish_herdr_subcommand agent start' -l workspace -r -d 'Workspace ID'
complete -c herdr -n '__fish_herdr_subcommand agent start' -l tab -r -d 'Tab ID'
complete -c herdr -n '__fish_herdr_subcommand agent start' -l split -xa 'right down' -d 'Split direction'
complete -c herdr -n '__fish_herdr_subcommand agent start' -l env -r -d 'Environment variable'
complete -c herdr -n '__fish_herdr_subcommand agent start' -l focus -d 'Focus started agent'
complete -c herdr -n '__fish_herdr_subcommand agent start' -l no-focus -d 'Do not focus started agent'
complete -c herdr -n '__fish_herdr_subcommand agent explain' -l json -d 'Output in JSON format'
complete -c herdr -n '__fish_herdr_subcommand agent explain' -l file -r -d 'File path'
complete -c herdr -n '__fish_herdr_subcommand agent explain' -l agent -r -d 'Agent label'

# pane
complete -c herdr -n '__fish_herdr_subcommand pane' -a 'list current get layout process-info neighbor edges focus resize zoom rename read split swap move close send-text send-keys report-agent report-agent-session release-agent report-metadata run'
complete -c herdr -n '__fish_herdr_subcommand pane list' -l workspace -r -d 'Workspace ID'
complete -c herdr -n '__fish_herdr_subcommand pane current' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane current' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane layout' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane layout' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane process-info' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane process-info' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane neighbor' -l direction -xa 'left right up down' -d Direction
complete -c herdr -n '__fish_herdr_subcommand pane neighbor' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane neighbor' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane edges' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane edges' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane focus' -l direction -xa 'left right up down' -d Direction
complete -c herdr -n '__fish_herdr_subcommand pane focus' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane focus' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane resize' -l direction -xa 'left right up down' -d Direction
complete -c herdr -n '__fish_herdr_subcommand pane resize' -l amount -r -d 'Resize ratio'
complete -c herdr -n '__fish_herdr_subcommand pane resize' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane resize' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane zoom' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane zoom' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane zoom' -l toggle -d 'Toggle zoom'
complete -c herdr -n '__fish_herdr_subcommand pane zoom' -l on -d 'Turn zoom on'
complete -c herdr -n '__fish_herdr_subcommand pane zoom' -l off -d 'Turn zoom off'
complete -c herdr -n '__fish_herdr_subcommand pane rename' -l clear -d 'Clear name'
complete -c herdr -n '__fish_herdr_subcommand pane read' -l source -xa 'visible recent recent-unwrapped' -d 'Read source'
complete -c herdr -n '__fish_herdr_subcommand pane read' -l lines -r -d 'Number of lines'
complete -c herdr -n '__fish_herdr_subcommand pane read' -l format -xa 'text ansi' -d 'Output format'
complete -c herdr -n '__fish_herdr_subcommand pane read' -l ansi -d 'Use ANSI format'
complete -c herdr -n '__fish_herdr_subcommand pane split' -l direction -xa 'right down' -d Direction
complete -c herdr -n '__fish_herdr_subcommand pane split' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane split' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane split' -l ratio -r -d 'Split ratio'
complete -c herdr -n '__fish_herdr_subcommand pane split' -l cwd -r -d 'Working directory'
complete -c herdr -n '__fish_herdr_subcommand pane split' -l env -r -d 'Environment variable'
complete -c herdr -n '__fish_herdr_subcommand pane split' -l focus -d 'Focus created pane'
complete -c herdr -n '__fish_herdr_subcommand pane split' -l no-focus -d 'Do not focus created pane'
complete -c herdr -n '__fish_herdr_subcommand pane swap' -l direction -xa 'left right up down' -d Direction
complete -c herdr -n '__fish_herdr_subcommand pane swap' -l pane -r -d 'Pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane swap' -l current -d 'Use current pane'
complete -c herdr -n '__fish_herdr_subcommand pane swap' -l source-pane -r -d 'Source pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane swap' -l target-pane -r -d 'Target pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane move' -l tab -r -d 'Tab ID'
complete -c herdr -n '__fish_herdr_subcommand pane move' -l split -xa 'right down' -d 'Split direction'
complete -c herdr -n '__fish_herdr_subcommand pane move' -l target-pane -r -d 'Target pane ID'
complete -c herdr -n '__fish_herdr_subcommand pane move' -l ratio -r -d Ratio
complete -c herdr -n '__fish_herdr_subcommand pane move' -l new-tab -d 'Move to new tab'
complete -c herdr -n '__fish_herdr_subcommand pane move' -l workspace -r -d 'Workspace ID'
complete -c herdr -n '__fish_herdr_subcommand pane move' -l label -r -d Label
complete -c herdr -n '__fish_herdr_subcommand pane move' -l new-workspace -d 'Move to new workspace'
complete -c herdr -n '__fish_herdr_subcommand pane move' -l tab-label -r -d 'Tab label'
complete -c herdr -n '__fish_herdr_subcommand pane move' -l focus -d 'Focus moved pane'
complete -c herdr -n '__fish_herdr_subcommand pane move' -l no-focus -d 'Do not focus moved pane'

# wait
complete -c herdr -n '__fish_herdr_subcommand wait' -a 'output agent-status'
complete -c herdr -n '__fish_herdr_subcommand wait output' -l match -r -d 'Text to match'
complete -c herdr -n '__fish_herdr_subcommand wait output' -l source -xa 'visible recent recent-unwrapped' -d Source
complete -c herdr -n '__fish_herdr_subcommand wait output' -l lines -r -d 'Number of lines'
complete -c herdr -n '__fish_herdr_subcommand wait output' -l timeout -r -d 'Timeout in ms'
complete -c herdr -n '__fish_herdr_subcommand wait output' -l regex -d 'Use regex matching'
complete -c herdr -n '__fish_herdr_subcommand wait output' -l raw -d 'Raw matching'
complete -c herdr -n '__fish_herdr_subcommand wait agent-status' -l status -xa 'idle working blocked done unknown' -d 'Target status'
complete -c herdr -n '__fish_herdr_subcommand wait agent-status' -l timeout -r -d 'Timeout in ms'

# session
complete -c herdr -n '__fish_herdr_subcommand session' -a 'list attach stop delete'
complete -c herdr -n '__fish_herdr_subcommand session list' -l json -d 'Output in JSON format'
complete -c herdr -n '__fish_herdr_subcommand session stop' -l json -d 'Output in JSON format'
complete -c herdr -n '__fish_herdr_subcommand session delete' -l json -d 'Output in JSON format'

# integration
complete -c herdr -n '__fish_herdr_subcommand integration' -a 'install uninstall status'
complete -c herdr -n '__fish_herdr_subcommand integration install' -xa 'pi omp claude codex copilot devin droid kimi opencode kilo hermes qodercli cursor'
complete -c herdr -n '__fish_herdr_subcommand integration uninstall' -xa 'pi omp claude codex copilot devin droid kimi opencode kilo hermes qodercli cursor'
complete -c herdr -n '__fish_herdr_subcommand integration status' -l outdated-only -d 'Show only outdated integrations'

# plugin
complete -c herdr -n '__fish_herdr_subcommand plugin' -a 'install uninstall link list config-dir unlink enable disable action log pane'
complete -c herdr -n '__fish_herdr_subcommand plugin install' -l ref -r -d 'Git ref'
complete -c herdr -n '__fish_herdr_subcommand plugin install' -l yes -d Auto-confirm
complete -c herdr -n '__fish_herdr_subcommand plugin link' -l disabled -d 'Link as disabled'
complete -c herdr -n '__fish_herdr_subcommand plugin list' -l plugin -r -d 'Plugin ID'
complete -c herdr -n '__fish_herdr_subcommand plugin list' -l json -d 'Output in JSON format'
complete -c herdr -n '__fish_herdr_subcommand plugin action' -xa 'list invoke'
complete -c herdr -n '__fish_herdr_subcommand plugin log' -a list
complete -c herdr -n '__fish_herdr_subcommand plugin log list' -l plugin -r -d 'Plugin ID'
complete -c herdr -n '__fish_herdr_subcommand plugin log list' -l limit -r -d 'Limit output lines'
complete -c herdr -n '__fish_herdr_subcommand plugin pane' -xa 'open focus close'
