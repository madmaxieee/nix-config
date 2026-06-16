{ pkgs, lib, ... }:

let
  zmx = pkgs.callPackage ../../packages/zmx.nix { };
in
rec {
  home.packages = [ zmx ];

  programs.fish.shellAbbrs = {
    x = lib.mkDefault "zmx";
  };

  programs.zsh = {
    zsh-abbr.abbreviations = programs.fish.shellAbbrs;
  };
}
