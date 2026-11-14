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

  # Antigravity denies view_file on skills whose realpath leaves its skills dir
  # and hides disable-model-invocation skills, so give it a dereferenced copy.
  agySkillsMaterialize = pkgs.writeShellScript "antigravity-skills-materialize" ''
    set -eu
    src="''${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
    dst="''${ANTIGRAVITY_CLI_CONFIG_DIR:-$HOME/.gemini/config}/skills"
    [ -d "$src" ] || exit 0
    if [ -L "$dst" ]; then rm "$dst"; fi
    mkdir -p "$dst"
    ${pkgs.rsync}/bin/rsync -rL --delete --exclude='/.*' --chmod=u+w "$src/" "$dst/"
    for f in "$dst"/*/SKILL.md; do
      if [ -f "$f" ] && [ "$(head -n1 "$f")" = "---" ]; then
        ${pkgs.gnused}/bin/sed -i '2,/^---$/{/^disable-model-invocation:[[:space:]]*true/d}' "$f"
      fi
    done
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
        description: Jujutsu (jj) version control and workspace rules, T3 Code worktree setup and handoff, and fff MCP file search. Use when working in a .jj repository or linked Git worktree, creating or handing off to a workspace or worktree, running VCS commands, or searching files when fff MCP tools are available.
        ---

      ''
      + builtins.readFile ../../dotfiles/codex/AGENTS.md
      + ''
        - In T3 Code on Antigravity, when `t3_worktree_status` reports `attached: false` and the task needs an isolated workspace, run the work via `delegate_task` with `isolation: "worktree"` (having the child rebase onto `trunk()` when independent work is expected) or `t3_thread_launch` with `workspaceStrategy` when asked for a new thread; never call `t3_worktree_handoff` on Antigravity (detaching the live ACP session mid-turn wedges the active run) or `jj workspace add` outside `workspacePaths` (blocked by Antigravity's path sandbox).
      '';
    };

    ".gemini/config/hooks/jj_guard.py".source = linkDotfile "codex/hooks/jj_guard.py";

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

  home.activation.antigravity_skills = lib.hm.dag.entryAfter [ "linkGeneration" "writeBoundary" ] ''
    run ${agySkillsMaterialize}
  '';
}
