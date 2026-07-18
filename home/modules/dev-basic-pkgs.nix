{
  config,
  pkgs,
  lib,
  sources,
  ...
}:

let
  loglit = pkgs.callPackage ../../packages/loglit.nix { };
  hunk = pkgs.callPackage ../../packages/hunk.nix { };
in
rec {
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.packages = with pkgs; [
    # better default tools
    # keep-sorted start
    delta
    dust
    eza
    fd
    ripgrep
    rm-improved
    sd
    # keep-sorted end

    # other
    # keep-sorted start
    btop
    chafa
    entr
    fzf
    glow
    graphviz
    hunk
    jq
    just
    loglit
    ouch
    parallel
    ripgrep-all
    rsync
    tealdeer
    typos
    unixtools.watch
    unixtools.xxd
    wget
    xz
    zstd
    # keep-sorted end
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
      hd = lib.mkDefault "hunk diff";
      js = lib.mkDefault "just";
      nd = lib.mkDefault "nix develop";
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
