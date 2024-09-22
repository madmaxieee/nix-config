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
    typos

    clang
    clang-tools
    uv
  ];

  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.sessionVariables.PAGER = "bat -p";

  programs.fish.shellAbbrs = { hm = "home-manager"; };
  programs.zsh.zsh-abbr.abbreviations = { hm = "home-manager"; };

  imports = [
    ./modules/fish.nix
    ./modules/zsh.nix
    ./modules/nvim.nix
    ./modules/tmux-ssh-host.nix

    ./modules/atuin.nix
    ./modules/zoxide.nix

    ./modules/git-google.nix

    # ./modules/scripts.nix
  ];
}
