{ hs_extra_config }:
{ config, pkgs, ... }:

let
  nixConfigPath = config.lib.custom.nixConfigPath;
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.packages = with pkgs; [ jq ];

  home.sessionPath = [ "${nixConfigPath}/dotfiles/script-kitty" ];

  home.file = {
    ".hammerspoon".source = linkDotfile "hammerspoon";

    # hack to make hammerspoon find nix binaries
    "nix-config/dotfiles/hammerspoon/nix_path.lua".text = ''
      NIX_PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
    '';

    "nix-config/dotfiles/hammerspoon/extra_config.lua".text = hs_extra_config;
  };

  xdg.configFile = {
    "skhd".source = linkDotfile "skhd";
    "yabai".source = linkDotfile "yabai";
    "aerospace".source = linkDotfile "aerospace";
    "sketchybar".source = linkDotfile "sketchybar";
  };

  imports = [ ./television.nix ];
}
