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
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "brackets" ];
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
    sessionVariables = {
      STARSHIP_CONFIG =
        "${config.home.homeDirectory}/.config/starship_zsh.toml";
    };
    autosuggestion.enable = true;
    defaultKeymap = "viins";
    initExtra = ''
      function _flush() {
        printf '\n%.0s' {1..$(tput lines)}
        zle reset-prompt
      }
      zle -N _flush
      bindkey '^L' _flush
    '';
  };

  programs.starship.enable = true;
  xdg.configFile = {
    "starship_zsh.toml".source = linkDotfile "starship/starship_zsh.toml";
  };
}
