{
  config,
  lib,
  pkgs,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
  fff-mcp = pkgs.callPackage ../../packages/fff-mcp.nix { };
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  codexHome = "${config.home.homeDirectory}/.codex";
in
{
  home.file = {
    ".codex/AGENTS.md".source = linkDotfile "codex/AGENTS.md";
    ".codex/fff-mcp".source = fff-mcp;
    ".codex/managed-config.toml".source = linkDotfile "codex/config.toml";
    ".codex/hooks/jj_guard.py".source = linkDotfile "codex/hooks/jj_guard.py";
    ".codex/hooks.json".source = linkDotfile "codex/hooks.json";
  };

  # Codex writes app settings and trust state here, so keep the live file writable.
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${python}/bin/python ${../../dotfiles/codex/merge-config.py} \
      ${lib.escapeShellArg "${codexHome}/config.toml"} \
      ${lib.escapeShellArg "${codexHome}/managed-config.toml"} \
      ${lib.escapeShellArg (lib.getExe fff-mcp)}
  '';
}
