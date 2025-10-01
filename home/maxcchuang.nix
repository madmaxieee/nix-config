{ pkgs, ... }:

{
  home.username = "maxcchuang";
  home.homeDirectory = "/usr/local/google/home/maxcchuang";

  home.packages = with pkgs; [ kitty minicom patchelf ];

  programs.fish = {
    functions = {
      gcert = ''
        bash -c 'if [[ -n $TMUX ]]; then
                  eval "$(tmux show-environment -s)"
                fi
                command gcert "$@"' --'';
    };
    shellAbbrs = {
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
      copy = "kitten clipboard";
      paste = "kitten clipboard -g";
    };
  };

  imports = [
    ./lib.nix

    ./modules/home-manager.nix
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

    ./modules/python.nix
    ./modules/rust.nix

    (import ./modules/mods.nix { provider = "gemini"; })
    ./modules/fabric-ai.nix
    ./modules/opencode.nix

    ./modules/git-google.nix
  ];
}
