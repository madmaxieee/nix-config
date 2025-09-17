{ config, pkgs, lib, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    coreutils
    gnused
    findutils

    vscode
    _1password-cli
    kitty
  ];

  home.sessionVariables = { "XDG_CONFIG_HOME" = config.xdg.configHome; };

  xdg.configFile = {
    "fish/completions/brew.fish".source = builtins.fetchurl {
      url =
        "https://raw.githubusercontent.com/Homebrew/brew/4.6.7/completions/fish/brew.fish";
      sha256 =
        "0714a26a5f9f999dc9d953c46e04ff2c64873cd69d34669aee8479954dd1565e";
    };
    "kitty" = {
      source = linkDotfile "kitty";
      recursive = false;
    };
    "fish/conf.d/kitty.fish".text = ''
      status is-interactive || exit 0
      if test $TERM = 'xterm-kitty'
        alias xssh='TERM=xterm-256color command ssh'
        if not set -q TMUX
          alias ssh='kitty +kitten ssh'
        end
      end
    '';
    "ghostty" = {
      source = linkDotfile "ghostty";
      recursive = false;
    };
    "espanso" = {
      source = linkDotfile "espanso";
      recursive = false;
    };
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
