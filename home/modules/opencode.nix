{ config, ... }:
let linkDotfile = config.lib.custom.linkDotfile;
in {
  programs.fish.functions.opencode = {
    body = ''
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
