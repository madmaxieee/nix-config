{ pkgs, lib, ... }:
rec {
  home.packages = with pkgs; [
    uv
    python3
    python314Packages.ipython
    ruff
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
