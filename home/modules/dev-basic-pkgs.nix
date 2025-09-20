{ config, pkgs, lib, ... }:

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
    htop
    rsync

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
      rm = lib.mkDefault "rip";
      rmm = lib.mkDefault "rm -rf";
      j = lib.mkDefault "just";
      lg = lib.mkDefault "lazygit";
    };
    shellAliases = {
      cat = lib.mkDefault "bat -p";
      l = lib.mkDefault "eza";
      ls = lib.mkDefault "eza --icons=auto";
      la = lib.mkDefault "eza --icons=auto --all";
      ll = lib.mkDefault "eza --icons=auto --long --group";
      lla = lib.mkDefault "eza --icons=auto --long --group --all";
      tree = lib.mkDefault "eza -T -a -I .git";
      icat = lib.mkDefault "kitten icat";
    };
  };

  programs.zsh = {
    zsh-abbr.abbreviations = {
      rm = lib.mkDefault "rip";
      rmm = lib.mkDefault "rm -rf";
      j = lib.mkDefault "just";
      lg = lib.mkDefault "lazygit";
    };
    shellAliases = {
      cat = lib.mkDefault "bat -p";
      l = lib.mkDefault "eza";
      ls = lib.mkDefault "eza --icons=auto";
      la = lib.mkDefault "eza --icons=auto --all";
      ll = lib.mkDefault "eza --icons=auto --long --group";
      lla = lib.mkDefault "eza --icons=auto --long --group --all";
      tree = lib.mkDefault "eza -T -a -I .git";
      icat = lib.mkDefault "kitten icat";
    };
  };
}
