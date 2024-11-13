{ config, pkgs, ... }:

{
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.packages = with pkgs; [
    eza
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
  ];

  programs.fastfetch.enable = true;

  programs.bat = {
    enable = true;
    config.theme = "catpuccin-mocha";
    themes = {
      catpuccin-mocha = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "d2bbee4f7e7d5bac63c054e4d8eca57954b31471";
          hash = "sha256-x1yqPCWuoBSx/cI94eA+AWwhiSA42cLNUOFJl7qjhmw=";
        };
        file = "themes/Catppuccin Mocha.tmTheme";
      };
    };
  };

  home.sessionVariables = {
    PAGER = "less";
    MANROFFOPT = "-c";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };

  programs.fish = {
    shellAbbrs = {
      rm = "rip";
      rmm = "rm -rf";
      j = "just";
      lg = "lazygit";
    };
    shellAliases = {
      cat = "bat -p";
      l = "eza";
      ls = "eza --icons";
      la = "eza --icons --all";
      ll = "eza --icons --long --group";
      lla = "eza --icons --long --group --all";
      tree = "eza -T -a -I .git";
      icat = "kitten icat";
    };
  };

  programs.zsh = {
    zsh-abbr.abbreviations = {
      rm = "rip";
      rmm = "rm -rf";
      j = "just";
      lg = "lazygit";
    };
    shellAliases = {
      cat = "bat -p";
      l = "eza";
      ls = "eza --icons";
      la = "eza --icons --all";
      ll = "eza --icons --long --group";
      lla = "eza --icons --long --group --all";
      tree = "eza -T -a -I .git";
      icat = "kitten icat";
    };
  };
}
