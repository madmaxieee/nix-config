{ config, pkgs, ... }:

{
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
      bindkey '^l' _flush

      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey '^[e' edit-command-line

      if echo $PATH | grep -q '/nix/store/'; then
        export IN_NIX_SHELL=1
      fi

      function vipe() {
        temp_file=/tmp/vipe.$$.txt
        touch $temp_file

        # read from stdin if it is a tty
        if [ ! -t 0 ]; then
          cat > $temp_file
        fi

        # spawn editor with stdio connected
        $EDITOR $temp_file < /dev/tty > /dev/tty || exit $?

        cat $temp_file
        rm $temp_file
      }
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
