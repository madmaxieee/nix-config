{ config, pkgs, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  # xdg.configFile = {
  #   "yazi/init.lua".source = linkDotfile "yazi/init.lua";
  #   "yazi/keymap.toml".source = linkDotfile "yazi/keymap.toml";
  #   "yazi/yazi.toml".source = linkDotfile "yazi/yazi.toml";
  # };

  programs.television.enable = true;
}
