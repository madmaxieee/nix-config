# Rex configuration

This directory is self-contained and does not require the Herdr configuration
or plugins. Install `init.lua` and the Python files together in
`${XDG_CONFIG_HOME:-$HOME/.config}/rex/`.

The session picker needs Rex, Python 3.11 or newer, and fzf on `PATH`. It also
uses zoxide directory history when available, eza for directory previews when
available, and `jj piper citc list` for Google CITC workspaces on supported hosts.

Saved projects come from `rex/sesh.toml` under the config directory, or the file
named by `REX_SESH_CONFIG`. The `sesh-<host>.toml` files are independent project
lists installed as `sesh.toml` by each host's Home Manager configuration.
For example:

```toml
[[session]]
name = "notes"
path = "~/notes"
startup_command = "exec nvim"
```

The agent restart action additionally needs `agent-session-hook.py` configured
in the agent's hooks; see the Claude/Codex settings and Rex Home Manager module.
