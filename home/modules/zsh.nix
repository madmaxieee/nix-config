{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.packages = with pkgs; [ eza bat rm-improved fzf lazygit ];

  programs.zsh = {
    enable = true;
    shellAliases = {
      cat = "bat -p";
      l = "eza";
      ls = "eza --icons";
      la = "eza --icons --all";
      ll = "eza --icons --long --group";
      lla = "eza --icons --long --group --all";
      tree = "eza -T -a -I .git";
      icat = "kitten icat";
      flush = "printf '\\n%.0s' {1..$(tput lines)}";
      clear = "flush";
    };
    zsh-abbr = {
      enable = true;
      abbreviations = {
        md = "mkdir -p";
        g = "git";
        lg = "lazygit";
        py = "python3";
        rm = "rip";
        rmm = "rm -rf";
      };
    };
    initExtra = ''
      function precmd() {
        echo
      }

      function _flush() {
        printf '\n%.0s' {1..$(tput lines)}
        zle reset-prompt
      }
      zle -N _flush
      bindkey '^L' _flush
    '';
    sessionVariables = {
      STARSHIP_CONFIG =
        "${config.home.homeDirectory}/.config/starship_zsh.toml";
      VI_MODE_SET_CURSOR = true;
      VI_MODE_CURSOR_NORMAL = 2;
      VI_MODE_CURSOR_VISUAL = 4;
      VI_MODE_CURSOR_INSERT = 6;
      VI_MODE_CURSOR_OPPEND = 0;
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "cursor" ];
    };
    autosuggestion = {
      enable = true;
      highlight = "fg=244";
      strategy = [ "history" "completion" "match_prev_cmd" ];
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "vi-mode" ];
      theme = "robbyrussell";
    };
  };

  programs.starship.enableZshIntegration = false;

  xdg.configFile = {
    "starship_zsh.toml".source = linkDotfile "starship/starship_zsh.toml";
  };
}
