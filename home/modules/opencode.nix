{ profile }:
{
  config,
  pkgs,
  lib,
  sources,
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
        pnpx opencode-ai@latest "$@"
      '';
    };
  };

  home.packages = [ rtk ];

  xdg.configFile = {
    # basic opencode config
    "opencode/AGENTS.md".source = linkDotfile "opencode/AGENTS.md";
    "opencode/opencode.jsonc".source = linkDotfile "opencode/opencode-${profile}.jsonc";
    "opencode/tui.jsonc".source = linkDotfile "opencode/tui.jsonc";
    "opencode/themes".source = linkDotfile "opencode/themes";

    # plugins
    "opencode/plugins/bun-guard.ts".source = linkDotfile "opencode/plugins/bun-guard.ts";
    "opencode/plugins/jj-guard.ts".source = linkDotfile "opencode/plugins/jj-guard.ts";
    "opencode/plugins/rtk.ts".source = linkDotfile "opencode/plugins/rtk.ts";

    # global skills
    "opencode/skills/productivity".source = "${sources.mattpocock-skills}/skills/productivity";

    # commands
    "opencode/commands/commit.md".source = linkDotfile "opencode/commands/commit.md";

    # omo-slim
    "opencode/oh-my-opencode-slim.json".source =
      linkDotfile "opencode/oh-my-opencode-slim-${profile}.json";
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
