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
  ];

  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.sessionVariables.PAGER = "bat -p";

  programs.zoxide.enable = true;
  home.sessionVariables = {
    "_ZO_DATA_DIR" = "${config.home.homeDirectory}/.local/share";
    "_ZO_RESOLVE_SYMLINKS" = "1";
    "_ZO_EXCLUDE_DIRS" = "/nix/store/*";
  };

  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
  };

  programs.fish.shellAbbrs = { hm = "home-manager"; };

  imports = [ ./modules/fish.nix ./modules/nvim.nix ./modules/git-google.nix ./modules/tmux-ssh-host.nix ];
}
