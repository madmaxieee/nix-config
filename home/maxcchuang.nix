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

    minicom

    kitty
  ];

  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.sessionVariables.PAGER = "bat -p";

  programs.fish = {
    shellAliases = {
      gcert = ''
        bash -c 'if [[ -n $TMUX ]]; then
                  eval "$(tmux show-environment -s)"
                fi
                command gcert "$@"' --'';
    };
    shellAbbrs = {
      hm = "home-manager";
      copy = "kitten clipboard";
      paste = "kitten clipboard -g";
    };
  };

  programs.zsh.zsh-abbr.abbreviations = {
    hm = "home-manager";
    copy = "kitten clipboard";
    paste = "kitten clipboard -g";
  };

  programs.git = {
    userName = "maxcchuang";
    userEmail = "maxcchuang@google.com";
    extraConfig = {
      http.cookiefile = "${config.home.homeDirectory}/.gitcookies";
    };
  };

  imports = [
    ./modules/fish.nix
    ./modules/zsh.nix
    ./modules/nvim.nix
    ./modules/tmux.nix

    ./modules/atuin.nix
    ./modules/zoxide.nix

    ./modules/git.nix

    # ./modules/scripts.nix
  ];
}
