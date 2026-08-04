{
  config,
  pkgs,
  lib,
  sources,
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
    # keep-sorted start
    coreutils
    diffutils
    findutils
    gawk
    gnugrep
    gnumake
    gnused
    gnutar
    # keep-sorted end

    macism
  ];

  xdg.configFile = {
    "fish/completions/brew.fish".source = "${sources.brew-src}/completions/fish/brew.fish";
    # homebrew cask config files
    "kitty".source = linkDotfile "kitty";
    "fish/conf.d/kitty.fish".text = ''
      status is-interactive || exit 0
      if test $TERM = 'xterm-kitty'
        alias ssh  'kitten ssh'
        alias icat 'kitten icat';
      end
    '';
    "ghostty".source = linkDotfile "ghostty";
    "espanso".source = linkDotfile "espanso";
  };

  home.file = {
    ".local/bin/ghostty".source =
      config.lib.file.mkOutOfStoreSymlink "/Applications/Ghostty.app/Contents/MacOS/ghostty";
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
