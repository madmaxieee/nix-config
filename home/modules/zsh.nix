{ config, ... }:

{
  programs.zsh = {
    enable = true;
    shellAliases = {
      flush = "printf '\\n%.0s' {1..$(tput lines)}";
      clear = "flush";
    };
    zsh-abbr = {
      enable = true;
      abbreviations = {
        md = "mkdir -p";
        g = "git";
        n = "nix";
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
      bindkey '^l' _flush

      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey '^[e' edit-command-line

      if echo $PATH | grep -q '/nix/store/'; then
        export IN_NIX_SHELL=1
      fi
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
}
