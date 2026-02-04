{
  config,
  pkgs,
  lib,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # replace darwin utils with gnu ones
    coreutils
    diffutils
    findutils

    gawk
    gnugrep
    gnumake
    gnused
    gnutar
  ];

  home.sessionVariables = {
    "XDG_CONFIG_HOME" = config.xdg.configHome;
  };

  xdg.configFile = {
    "fish/completions/brew.fish".source = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/Homebrew/brew/5.0.3/completions/fish/brew.fish";
      sha256 = "f8ee0c4e9ee16d673032cd6f966dbca8ed5a168f9c7e91a536c593e041947830";
    };
    "kitty".source = linkDotfile "kitty";
    "fish/conf.d/kitty.fish".text = ''
      status is-interactive || exit 0
      if test $TERM = 'xterm-kitty'
        alias xssh='TERM=xterm-256color command ssh'
        if not set -q TMUX
          alias ssh='kitty +kitten ssh'
        end
      end
    '';
    "ghostty".source = linkDotfile "ghostty";
    "espanso".source = linkDotfile "espanso";
  };

  programs.fish.shellAbbrs = {
    o = lib.mkDefault "open";
    copy = lib.mkDefault "pbcopy";
    paste = lib.mkDefault "pbpaste";
    dr = lib.mkDefault "darwin-rebuild";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    o = lib.mkDefault "open";
    copy = lib.mkDefault "pbcopy";
    paste = lib.mkDefault "pbpaste";
    dr = lib.mkDefault "darwin-rebuild";
  };
}
