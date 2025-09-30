{ provider }:
{ config, pkgs, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  home.packages = with pkgs; [ mods ];

  xdg.configFile = {
    "mods" = {
      source = linkDotfile "mods";
      recursive = true;
    };
  };

  imports = [ ../password-store.nix ] ++ (if provider == "openai" then
    [ ./openai.nix ]
  else if provider == "gemini" then
    [ ./gemini.nix ]
  else
    (throw ("mods: provider must be one of openai or gemini")));
}
