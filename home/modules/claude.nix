{
  config,
  lib,
  pkgs,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
  fff-mcp = pkgs.callPackage ../../packages/fff-mcp.nix { };
  homeDirectory = config.home.homeDirectory;
  mcpConfig = pkgs.writeText "claude-mcp.json" (
    builtins.toJSON {
      mcpServers.fff = {
        type = "stdio";
        command = lib.getExe fff-mcp;
        args = [ "--no-update-check" ];
      };
    }
  );
in
{
  # Shared with Codex so the agents can't drift apart.
  home.file = {
    ".claude/CLAUDE.md".source = linkDotfile "codex/AGENTS.md";
    ".claude/hooks/jj_guard.py".source = linkDotfile "codex/hooks/jj_guard.py";
  };

  # Claude Code writes app settings to settings.json and user-scoped MCP servers
  # alongside its login state in ~/.claude.json, so keep both live files writable.
  home.activation.claudeConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.python3}/bin/python ${../../dotfiles/claude/merge-config.py} \
      ${lib.escapeShellArg "${homeDirectory}/.claude/settings.json"} \
      ${../../dotfiles/claude/settings.json}
    run ${pkgs.python3}/bin/python ${../../dotfiles/claude/merge-config.py} \
      ${lib.escapeShellArg "${homeDirectory}/.claude.json"} \
      ${mcpConfig}
  '';
}
