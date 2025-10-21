{ config, pkgs, lib, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  home.file = {
    ".local/bin/opencode" = {
      executable = true;
      text = ''
        #!${pkgs.fish}/bin/fish
        set -x GEMINI_API_KEY (pass gemini/cli 2> /dev/null)
        bunx --bun opencode-ai@latest $argv
      '';
    };
  };

  xdg.configFile.opencode.source = linkDotfile "opencode";

  programs.fish = { shellAbbrs.oc = lib.mkDefault "opencode"; };
  programs.zsh = { zsh-abbr.abbreviations.oc = lib.mkDefault "opencode"; };

  imports = [ ./web-dev.nix ];
}
