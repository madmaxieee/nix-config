{
  config,
  lib,
  pkgs,
  ...
}:

let
  fff-mcp = pkgs.callPackage ../../packages/fff-mcp.nix { };
  linkDotfile = config.lib.custom.linkDotfile;

  jjGuardCmd = "${pkgs.python3}/bin/python3 \"${config.home.homeDirectory}/.gemini/config/hooks/jj_guard.py\"";
  agyJjGuardInstall = pkgs.writeShellScript "antigravity-jj-guard-install" ''
    set -eu
    config_dir="''${ANTIGRAVITY_CLI_CONFIG_DIR:-$HOME/.gemini/config}"
    [ -d "$config_dir" ] || exit 0
    hooks="$config_dir/hooks.json"
    [ -s "$hooks" ] || echo '{}' > "$hooks"
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    ${pkgs.jq}/bin/jq --arg cmd "${jjGuardCmd}" '
      ."jj-guard" = {
        "SessionStart": [
          { "type": "command", "command": ($cmd + " agy session_start"), "timeout": 5 }
        ],
        "PreToolUse": [
          {
            "matcher": "run_command",
            "hooks": [
              { "type": "command", "command": ($cmd + " agy pre_tool"), "timeout": 5 }
            ]
          }
        ]
      }
    ' "$hooks" > "$tmp"
    cat "$tmp" > "$hooks"
  '';
in
{
  home.file = {
    ".agents/skills/t3-model-routing" = {
      force = true;
      source = linkDotfile "agents/skills/t3-model-routing";
    };

    # Antigravity (CLI and T3 Code ACP) discovers global skills via config/skills,
    # not config/AGENTS.md; expose shared global instructions as a skill.
    ".agents/skills/global-instructions/SKILL.md" = {
      force = true;
      text = ''
        ---
        name: global-instructions
        description: Jujutsu (jj) version control and workspace rules, T3 Code worktree setup, and fff MCP file search. Use when working in a .jj repository or linked Git worktree, creating a workspace or worktree, running VCS commands, or searching files when fff MCP tools are available.
        ---

      ''
      + builtins.readFile ../../dotfiles/codex/AGENTS.md;
    };

    ".gemini/config/hooks/jj_guard.py".source = linkDotfile "codex/hooks/jj_guard.py";
    ".gemini/config/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";

    ".gemini/config/mcp_config.json" = {
      force = true;
      text = builtins.toJSON {
        mcpServers.fff = {
          command = lib.getExe fff-mcp;
          args = [ "--no-update-check" ];
          disabled = false;
        };
      };
    };
  };

  home.activation.antigravity_jj_guard = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${agyJjGuardInstall}
  '';
}
