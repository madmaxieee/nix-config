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

  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
    };
  };
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package =
      if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
  };

  imports = if provider == "openai" then
    [ ./openai.nix ]
  else if provider == "gemini" then
    [ ./gemini.nix ]
  else
    (throw ("mods provider must be openai or gemini"));
}
