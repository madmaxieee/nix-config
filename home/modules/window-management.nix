{ hs_extra_config }:
{ config, pkgs, ... }:

let
  script-kit = pkgs.callPackage ../../packages/script-kit.nix { };
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.packages = with pkgs; [ jq script-kit ];

  home.sessionPath = [ "${config.home.homeDirectory}/.kit/bin" ];

  home.file = {
    ".hammerspoon" = {
      source = linkDotfile "hammerspoon";
      recursive = false;
    };
    ".kenv" = {
      source = linkDotfile "kenv";
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
