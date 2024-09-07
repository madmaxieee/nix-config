{ config, pkgs, ... }:

{
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.username = "maxcchuang";
  home.homeDirectory = "/usr/local/google/home/maxcchuang";

  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    sd
    difftastic
    wget
    rm-improved

    tealdeer
    tokei
    typos

    clang
    clang-tools
    uv
  ];

  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.sessionVariables.PAGER = "bat -p";

  programs.fish.shellAbbrs = { hm = "home-manager"; };

  imports = [
    ./modules/fish.nix
    ./modules/nvim.nix
    ./modules/tmux-ssh-host.nix
    ./modules/git-google.nix
  ];
}
