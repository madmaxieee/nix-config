{ pkgs, lib, ... }:
rec {
  home.packages = with pkgs; [
    uv
    python313
    python313Packages.ipython
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
