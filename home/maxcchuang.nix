{ pkgs, ... }:

{
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.username = "maxcchuang";
  home.homeDirectory = "/usr/local/google/home/maxcchuang";

  home.packages = with pkgs; [ minicom kitty ];

  programs.fish = {
    shellAliases = {
      gcert = ''
        bash -c 'if [[ -n $TMUX ]]; then
                  eval "$(tmux show-environment -s)"
                fi
                command gcert "$@"' --'';
    };
    shellAbbrs = {
      hm = "home-manager";
      copy = "kitten clipboard";
      paste = "kitten clipboard -g";
    };
  };

  programs.zsh = {
    shellAliases = {
      gcert = ''
        bash -c 'if [[ -n $TMUX ]]; then
                  eval "$(tmux show-environment -s)"
                fi
                command gcert "$@"' --'';
    };
    zsh-abbr.abbreviations = {
      hm = "home-manager";
      copy = "kitten clipboard";
      paste = "kitten clipboard -g";
    };
  };

  imports = [
    ./modules/dev-basic-pkgs.nix

    ./modules/fish.nix
    ./modules/zsh.nix
    ./modules/nvim.nix
    ./modules/tmux.nix

    ./modules/scripts.nix

    ./modules/atuin.nix
    ./modules/zoxide.nix
    ./modules/yazi

    ./modules/git.nix
    ./modules/git-google.nix
    (import ./modules/mods { provider = "gemini"; })

    ./modules/python.nix

    ./modules/gscripts.nix
  ];
}
