{ config, pkgs, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  home.packages = with pkgs; [ mprocs ];
  xdg.configFile = { "mprocs".source = linkDotfile "mprocs"; };
}
