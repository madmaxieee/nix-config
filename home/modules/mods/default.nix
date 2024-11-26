{ provider }:
{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.packages = with pkgs; [ mods ];

  xdg.configFile = {
    "mods" = {
      source = linkDotfile "mods";
      recursive = true;
    };
  };

  programs.password-store.enable = true;
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  imports = if provider == "openai" then
    [ ./openai.nix ]
  else if provider == "gemini" then
    [ ./gemini.nix ]
  else
    (throw ("mods provider must be openai or gemini"));
}
