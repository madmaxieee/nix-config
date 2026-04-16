{ profile }:
{
  config,
  pkgs,
  lib,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
  fff-mcp = pkgs.callPackage ../../packages/fff-mcp.nix { };
  rtk = pkgs.callPackage ../../packages/rtk.nix { };
in
rec {
  home.file = {
    ".local/bin/opencode" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        export PATH="${
          lib.makeBinPath [
            fff-mcp
            rtk
          ]
        }:$PATH"
        ${lib.optionalString (profile == "work") ''
          if [[ -z "$GEMINI_API_KEY" ]]; then
            export GEMINI_API_KEY=$(pass gemini/cli 2>/dev/null)
          fi
        ''}
        pnpx opencode-ai@latest "$@"
      '';
    };
  };

  home.packages = [ rtk ];

  home.activation = {
    rtk_init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe rtk} init -g --opencode
    '';
  };

  xdg.configFile = {
    "opencode/AGENTS.md".source = linkDotfile "opencode/AGENTS.md";
    "opencode/opencode.jsonc".source = linkDotfile "opencode/opencode-${profile}.jsonc";
    "opencode/tui.jsonc".source = linkDotfile "opencode/tui.jsonc";
    "opencode/commands/review.md".source = linkDotfile "opencode/commands/review.md";
    "opencode/commands/jj-desc.md".source = linkDotfile "opencode/commands/jj-desc.md";
    "opencode/themes".source = linkDotfile "opencode/themes";
  };

  programs.fish = {
    shellAbbrs.oc = lib.mkDefault "opencode";
  };

  programs.zsh.zsh-abbr.abbreviations = programs.fish.shellAbbrs;

  imports = [
    ./password-store.nix
    ./web-dev.nix
  ];
}
