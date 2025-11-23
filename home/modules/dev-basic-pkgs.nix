{ config, pkgs, lib, sources, ... }:

rec {
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.packages = with pkgs; [
    eza
    ripgrep
    fd
    sd
    wget
    rm-improved
    dust
    riffdiff

    parallel
    entr
    fzf
    jq
    lazygit
    just
    htop
    rsync
    ouch

    unixtools.watch
    unixtools.xxd

    tealdeer
    navi
    typos
    ripgrep-all

    graphviz
  ];

  programs.man.enable = true;

  programs.less.enable = true;

  programs.bat = {
    enable = true;
    config.theme = "tokyonight-moon";
    themes = {
      tokyonight-moon = {
        src = sources.tokyonight;
        file = "extras/sublime/tokyonight_moon.tmTheme";
      };
    };
  };

  home.sessionVariables = {
    MANROFFOPT = "-c";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    PAGER = "less -FR";
  };

  programs.fastfetch.enable = true;

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
    zsh-abbr.abbreviations = programs.fish.shellAbbrs;
    shellAliases = programs.fish.shellAliases;
  };
}
