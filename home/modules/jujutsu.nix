{ config, pkgs, ... }:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
rec {
  home.packages = with pkgs; [
    jujutsu
    delta
  ];

  xdg.configFile."jj".source = linkDotfile "jujutsu";

  programs.fish.shellAbbrs = {
    j = "jj";
  };

  programs.zsh = {
    zsh-abbr.abbreviations = programs.fish.shellAbbrs;
  };
}
