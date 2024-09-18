{ hs_extra_config }:
{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.packages = with pkgs; [ jq ];

  home.file = {
    ".hammerspoon" = {
      source = linkDotfile "hammerspoon";
      recursive = false;
    };
    # hack to make hammerspoon find nix binaries
    "nix-config/dotfiles/hammerspoon/nix_path.lua".text = ''
      NIX_PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
    '';

    "nix-config/dotfiles/hammerspoon/extra_config.lua".text = hs_extra_config;
  };

  xdg.configFile = {
    "skhd" = {
      source = linkDotfile "skhd";
      recursive = false;
    };
    "yabai" = {
      source = linkDotfile "yabai";
      recursive = false;
    };
    "sketchybar" = {
      source = linkDotfile "sketchybar";
      recursive = false;
    };
  };
}
