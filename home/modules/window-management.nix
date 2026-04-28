{ profile }:
{ config, pkgs, ... }:

let
  nixConfigPath = config.lib.custom.nixConfigPath;
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.packages = with pkgs; [
    jq
    sqlite
  ];

  home.sessionPath = [ "${nixConfigPath}/dotfiles/script-kitty" ];

  home.file = {
    ".hammerspoon".source = linkDotfile "hammerspoon";

    # hack to make hammerspoon find nix binaries
    "nix-config/dotfiles/hammerspoon/nix_path.lua".text = ''
      NIX_PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
    '';

    "nix-config/dotfiles/hammerspoon/extra_config.lua".source =
      linkDotfile "hammerspoon/extra_config-${profile}.lua";
  };

  xdg.configFile = {
    "skhd".source = linkDotfile "skhd";
    "yabai".source = linkDotfile "yabai";
    "aerospace".source = linkDotfile "aerospace";
    "sketchybar".source = linkDotfile "sketchybar";
  };

  imports = [ ./television.nix ];
}
