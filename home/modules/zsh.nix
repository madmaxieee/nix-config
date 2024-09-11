{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  programs.starship.enable = true;
  programs.tmux.enable = true;

  home.packages = with pkgs; [ eza bat rm-improved fzf lazygit ];

  xdg.configFile = {
    "starship_google.toml".source = linkDotfile "starship/starship_google.toml";
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      md = "mkdir -p";
      g = "git";
      lg = "lazygit";
      py = "python3";
      rm = "rip";
      rmm = "rm -rf";
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
  };

  programs.atuin = { enable = true; };

  programs.zoxide.enable = true;
  programs.zsh.sessionVariables = {
    "_ZO_DATA_DIR" = "${config.home.homeDirectory}/.local/share";
    "_ZO_RESOLVE_SYMLINKS" = "1";
    "_ZO_EXCLUDE_DIRS" = "/nix/store/*";
  };
}
