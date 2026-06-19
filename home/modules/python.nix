{ pkgs, lib, ... }:
rec {
  home.packages = with pkgs; [
    uv
    python313
    python313Packages.ipython
  ];

  programs.fish = {
    shellAbbrs = {
      py = lib.mkDefault "python3";
      ipy = lib.mkDefault "ipython";
    };
  };

  programs.zsh = {
    zsh-abbr.abbreviations = programs.fish.shellAbbrs;
  };
}
