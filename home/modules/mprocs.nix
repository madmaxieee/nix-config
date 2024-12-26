{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.packages = with pkgs; [ mprocs ];
  xdg.configFile = {
    "mprocs" = {
      source = linkDotfile "mprocs";
      recursive = false;
    };
  };
}
