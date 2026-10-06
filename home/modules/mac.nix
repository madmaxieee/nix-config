{
  config,
  pkgs,
  lib,
  sources,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
  gnuTools = pkgs.runCommand "gnu-tools-prefixed" { } ''
    mkdir -p "$out/bin"
    ${lib.concatMapAttrsStringSep "\n"
      (command: package: ''
        ln -s "${package}/bin/${command}" "$out/bin/g${command}"
      '')
      {
        # keep-sorted start
        awk = pkgs.gawk;
        cmp = pkgs.diffutils;
        diff = pkgs.diffutils;
        diff3 = pkgs.diffutils;
        find = pkgs.findutils;
        grep = pkgs.gnugrep;
        make = pkgs.gnumake;
        sdiff = pkgs.diffutils;
        sed = pkgs.gnused;
        tar = pkgs.gnutar;
        xargs = pkgs.findutils;
        # keep-sorted end
      }
    }
  '';
in
{
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Keep native macOS command names; GNU tools are available with a g prefix.
    coreutils-prefixed
    gnuTools
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
