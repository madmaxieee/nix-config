{ config, pkgs, ... }:

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
        "https://raw.githubusercontent.com/Homebrew/brew/4.5.6/completions/fish/brew.fish";
      sha256 =
        "4c530d0297b65fa538cfd358e03da3726badfe1c5fb2b797febb1119f58e1dde";
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
    o = "open";
    copy = "pbcopy";
    paste = "pbpaste";
    dr = "darwin-rebuild";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    o = "open";
    copy = "pbcopy";
    paste = "pbpaste";
    dr = "darwin-rebuild";
  };
}
