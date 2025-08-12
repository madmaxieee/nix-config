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
    dust

    parallel
    entr
    fzf
    jq
    lazygit
    just

    tealdeer
    typos
    ripgrep-all
  ];

  programs.fastfetch.enable = true;

  programs.bat = {
    enable = true;
    config.theme = "tokyonight-moon";
    themes = {
      tokyonight-moon = {
        src = pkgs.fetchFromGitHub {
          owner = "folke";
          repo = "tokyonight.nvim";
          rev = "9758827c3b380ba89da4a2212b6255d01afbcf08";
          hash = "sha256-qEmfBs+rKP25RlS7VxNSw9w4GnlZiiEchs17nJg7vsE=";
        };
        file = "extras/sublime/tokyonight_moon.tmTheme";
      };
    };
  };

  home.sessionVariables = {
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
      ls = "eza --icons=auto";
      la = "eza --icons=auto --all";
      ll = "eza --icons=auto --long --group";
      lla = "eza --icons=auto --long --group --all";
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
      ls = "eza --icons=auto";
      la = "eza --icons=auto --all";
      ll = "eza --icons=auto --long --group";
      lla = "eza --icons=auto --long --group --all";
      tree = "eza -T -a -I .git";
      icat = "kitten icat";
    };
  };
}
