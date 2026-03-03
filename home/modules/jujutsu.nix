{
  use_system_binary ? false,
}:
{ config, pkgs, ... }:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
rec {
  home.packages =
    with pkgs;
    [
      delta
    ]
    ++ pkgs.lib.optional (!use_system_binary) jujutsu;

  xdg.configFile = {
    "jj/config.toml".source = linkDotfile "jujutsu/config.toml";
    "jj/conf.d".source = linkDotfile "jujutsu/conf.d";
  };

  programs.fish.shellAbbrs = {
    j = "jj";
  };

  programs.zsh = {
    zsh-abbr.abbreviations = programs.fish.shellAbbrs;
  };
}
