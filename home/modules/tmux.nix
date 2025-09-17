{ config, pkgs, lib, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
  defaultCommand = if pkgs.stdenv.isDarwin then
    ''
      set-option -g default-command "${pkgs.reattach-to-user-namespace}/bin/reattach-to-user-namespace -l ${pkgs.fish}/bin/fish"''
  else
    "";
in {
  home.packages = with pkgs; [ sesh fzf jq fd ];

  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    prefix = "C-Space";
    plugins = with pkgs; [
      tmuxPlugins.yank
      tmuxPlugins.copycat
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g status-left-length 100
          set -g status-right-length 100

          set -g status-left " #{E:@catppuccin_status_session}"
          set -g status-right "#{E:@catppuccin_status_application}"
          set -ag status-right "#{E:@catppuccin_status_session}"

          set -g @catppuccin_flavour 'mocha'
          set -g @catppuccin_window_status_style 'rounded'
          set -g @catppuccin_window_current_text " #{pane_current_path}#{?window_zoomed_flag, ,}"
          set -g @catppuccin_status_right_separator ' '
          set -g @catppuccin_status_connect_separator 'no'
        '';
      }
    ];
    extraConfig = ''
      ${defaultCommand}
      source-file ${nix_config_path}/dotfiles/tmux/tmux.conf'';
  };

  programs.fish = {
    shellAliases = {
      t = lib.mkDefault "${config.xdg.configHome}/tmux/scripts/sesh.sh";
    };
    shellAbbrs = {
      ta = lib.mkDefault "tmux attach";
      tn = lib.mkDefault "tmux new -s";
    };
  };

  programs.zsh = {
    shellAliases = {
      t = lib.mkDefault "${config.xdg.configHome}/tmux/scripts/sesh.sh";
    };
    zsh-abbr.abbreviations = {
      ta = lib.mkDefault "tmux attach";
      tn = lib.mkDefault "tmux new -s";
    };
  };

  xdg.configFile = {
    "tmux/scripts" = {
      source = linkDotfile "tmux/scripts";
      recursive = true;
    };
  };
}
