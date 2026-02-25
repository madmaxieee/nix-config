{ config, pkgs, ... }:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.packages = with pkgs; [
    jujutsu
    delta
  ];
  xdg.configFile."jj".source = linkDotfile "jujutsu";
}
