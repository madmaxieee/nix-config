{
  config,
  lib,
  pkgs,
  ...
}:

let
  fff-mcp = pkgs.callPackage ../../packages/fff-mcp.nix { };
in
{
  home.file.".gemini/config/AGENTS.md".source = config.lib.custom.linkDotfile "codex/AGENTS.md";

  home.file.".gemini/config/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";

  home.file.".gemini/config/mcp_config.json" = {
    force = true;
    text = builtins.toJSON {
      mcpServers.fff = {
        command = lib.getExe fff-mcp;
        args = [ "--no-update-check" ];
        disabled = false;
      };
    };
  };
}
