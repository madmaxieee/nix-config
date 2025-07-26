{ pkgs, ... }:

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
    initContent = ''
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

      if [ -f ~/.zshrc.local ]; then
        source ~/.zshrc.local
      fi
    '';
    sessionVariables = { ZVM_VI_ESCAPE_BINDKEY = "kj"; };
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "cursor" ];
    };
    autosuggestion = {
      enable = true;
      highlight = "fg=244";
      strategy = [ "history" "completion" "match_prev_cmd" ];
    };
    plugins = [{
      name = "zsh-vi-mode";
      file = "./share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      src = pkgs.zsh-vi-mode;
    }];
  };

  programs.starship.enableZshIntegration = true;
}
