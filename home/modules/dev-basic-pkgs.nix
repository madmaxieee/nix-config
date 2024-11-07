{ config, pkgs, ... }:

{
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    sd
    difftastic
    wget
    rm-improved

    parallel
    entr
    fzf
    jq
    lazygit
    just

    tealdeer
    typos

    kitty
  ];

  programs.fastfetch.enable = true;

  home.sessionVariables.PAGER = "bat -p";
}
