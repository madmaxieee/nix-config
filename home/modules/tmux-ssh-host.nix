{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.packages = [ pkgs.sesh pkgs.fzf pkgs.jq ];

  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    # different prefix
    prefix = "C-b";
    plugins = with pkgs; [
      tmuxPlugins.yank
      tmuxPlugins.copycat
      {
        plugin = tmuxPlugins.catppuccin;
        # different catppuccin flavor
        extraConfig = ''
          set -g @catppuccin_flavour 'frappe'
          set -g @catppuccin_window_left_separator ""
          set -g @catppuccin_window_right_separator " "
          set -g @catppuccin_window_middle_separator " █"
          set -g @catppuccin_window_number_position "right"
          set -g @catppuccin_window_default_fill "number"
          set -g @catppuccin_window_current_fill "number"
          set -g @catppuccin_window_current_text "#{pane_current_path}#{?window_zoomed_flag, ,}"
          set -g @catppuccin_status_modules_left "session"
          set -g @catppuccin_status_left_separator  " "
          set -g @catppuccin_status_right_separator " "
          set -g @catppuccin_status_right_separator_inverse "no"
          set -g @catppuccin_status_fill "icon"
          set -g @catppuccin_status_connect_separator "no"
          set -g @catppuccin_directory_text "#{pane_current_path}"
          set -g @catppuccin_date_time_text "%H:%M"
        '';
      }
    ];
    extraConfig = "source-file ${nix_config_path}/dotfiles/tmux/tmux.conf";
  };

  programs.fish = {
    shellAbbrs = { t = "${config.xdg.configHome}/tmux/scripts/sesh.sh"; };
    shellAliases = { ta = "tmux attach"; };
  };

  xdg.configFile = {
    "tmux/scripts" = {
      source = linkDotfile "tmux/scripts";
      recursive = true;
    };
  };
}