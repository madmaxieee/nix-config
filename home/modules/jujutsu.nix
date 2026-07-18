{
  use_system_binary ? false,
}:
{ config, pkgs, ... }:

let
  linkDotfile = config.lib.custom.linkDotfile;
  hunk = pkgs.callPackage ../../packages/hunk.nix { };
in
rec {
  home.packages =
    with pkgs;
    pkgs.lib.optional (!use_system_binary) jujutsu
    ++ [
      # diff pagers
      delta
      hunk

      # fix tools
      keep-sorted
      nixfmt
      ruff
      shfmt
      stylua

      # other tools
      lazyjj
    ];

  xdg.configFile = {
    "jj/config.toml".source = linkDotfile "jujutsu/config.toml";
    "jj/conf.d".source = linkDotfile "jujutsu/conf.d";
  };

  programs.fish.shellAbbrs = {
    j = "jj";
    jg = "jj git";
    lj = "lazyjj";
  };

  programs.zsh = {
    zsh-abbr.abbreviations = programs.fish.shellAbbrs;
  };
}
