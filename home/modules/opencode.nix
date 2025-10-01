{ config, pkgs, ... }:
let linkDotfile = config.lib.custom.linkDotfile;
in {
  home.file = {
    ".local/bin/opencode".text = ''
      #!${pkgs.fish}/bin/fish
      set -x GEMINI_API_KEY (pass gemini/cli 2> /dev/null)
      pnpx opencode-ai@latest $argv
    '';
  };

  xdg.configFile = {
    opencode = {
      source = linkDotfile "opencode";
      recursive = true;
    };
  };

  imports = [ ./web-dev.nix ];
}
