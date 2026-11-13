{
  config,
  pkgs,
  lib,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;

  # Antigravity CLI's hooks.json can contain other tools' managed blocks, so
  # upsert our own named block instead of symlinking the whole file. Claude
  # Code and Codex get the same hook from their dotfiles settings.
  agentSessionHook = "${pkgs.python3}/bin/python3 ${config.xdg.configHome}/rex/agent-session-hook.py";
  agyAgentSessionHookInstall = pkgs.writeShellScript "rex-agy-agent-session-hook-install" ''
    set -eu
    config_dir="''${ANTIGRAVITY_CLI_CONFIG_DIR:-$HOME/.gemini/config}"
    [ -d "$config_dir" ] || exit 0
    hooks="$config_dir/hooks.json"
    [ -s "$hooks" ] || echo '{}' > "$hooks"
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    ${pkgs.jq}/bin/jq --arg cmd "${agentSessionHook} agy" '
      ."rex-agent-session" = {
        "PreInvocation": [ { "type": "command", "command": $cmd, "timeout": 5 } ]
      }
    ' "$hooks" > "$tmp"
    cat "$tmp" > "$hooks"
  '';
in
{
  home.packages = [
    pkgs.fzf
    pkgs.python3
  ];

  imports = [ ./zoxide.nix ];

  xdg.configFile."rex/init.lua".source = linkDotfile "rex/init.lua";
  xdg.configFile."rex/sesh-picker.py".source = linkDotfile "rex/sesh-picker.py";
  xdg.configFile."rex/citc.py".source = linkDotfile "rex/citc.py";
  xdg.configFile."rex/session_config.py".source = linkDotfile "rex/session_config.py";
  xdg.configFile."rex/agent-session-hook.py".source = linkDotfile "rex/agent-session-hook.py";
  xdg.configFile."rex/restart-agent.py".source = linkDotfile "rex/restart-agent.py";
  # Declares the rex global for lua_ls when editing ~/.config/rex/init.lua.
  xdg.configFile."rex/.luarc.json".source = linkDotfile "rex/.luarc.json";

  home.activation.rex_agy_agent_session_hook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${agyAgentSessionHookInstall}
  '';

  # Nix shell initialization can replace the PATH Rex supplies to terminals.
  programs.fish.interactiveShellInit = ''
    if set -q REX_BIN_DIR
        fish_add_path --path --prepend --move $REX_BIN_DIR
    end
  '';
  programs.zsh.initContent = ''
    if [ -n "$REX_BIN_DIR" ]; then
      export PATH="$REX_BIN_DIR:$PATH"
    fi
  '';
}
