{
  config,
  pkgs,
  lib,
  sources,
  ...
}:

rec {
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.packages = with pkgs; [
    # better default tools
    delta
    dust
    eza
    fd
    ripgrep
    rm-improved
    sd

    # other
    btop
    chafa
    entr
    fzf
    glow
    graphviz
    jq
    just
    ouch
    parallel
    riffdiff
    ripgrep-all
    rsync
    tealdeer
    typos
    unixtools.watch
    unixtools.xxd
    wget

    # compression tools
    xz
    zstd
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
    XDG_CONFIG_HOME = config.xdg.configHome;
  };

  programs.fastfetch.enable = true;

  programs.fish = {
    shellAbbrs = {
      js = lib.mkDefault "just";
      lg = lib.mkDefault "lazygit";
      rm = lib.mkDefault "rip";
      rmm = lib.mkDefault "rm -rf";
    };
    shellAliases = {
      cat = lib.mkDefault "bat -p";
      l = lib.mkDefault "eza";
      la = lib.mkDefault "eza --icons=auto --all";
      ll = lib.mkDefault "eza --icons=auto --long --group";
      lla = lib.mkDefault "eza --icons=auto --long --group --all";
      ls = lib.mkDefault "eza --icons=auto";
      tree = lib.mkDefault "eza -T -a -I .git";
    };
  };

  programs.zsh = {
    zsh-abbr.abbreviations = programs.fish.shellAbbrs;
    shellAliases = programs.fish.shellAliases;
  };
}
