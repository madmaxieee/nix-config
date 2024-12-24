{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.packages = with pkgs; [ jujutsu ];
  home.sessionVariables.JJ_CONFIG = "${config.xdg.configHome}/jj/config.toml";
  xdg.configFile = {
    "jj" = {
      source = linkDotfile "jujutsu";
      recursive = false;
    };
  };
}
