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
    ".simplebarrc".source = linkDotfile "simple-bar/simplebarrc";
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
    "ubersicht/widgets/simple-bar".source = builtins.fetchGit {
      url = "git@github.com:madmaxieee/simple-bar.git";
      rev = "1240a1d5e0aa546a77ae680277e87aa5b39d46b1";
    };
  };
}
