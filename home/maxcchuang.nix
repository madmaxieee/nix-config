{ config, pkgs, ... }:

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

  programs.git = {
    userName = "Max Chuang";
    userEmail = "maxcchuang@google.com";
    extraConfig = {
      http.cookiefile = "${config.home.homeDirectory}/.gitcookies";
    };
    includes = [
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        contentSuffix = "github";
        contents = {
          user.name = "madmaxieee";
          user.email = "76544194+madmaxieee@users.noreply.github.com";
        };
      }
      {
        condition = "hasconfig:remote.*.url:ssh://soft/**";
        contentSuffix = "soft";
        contents = {
          user.name = "madmaxieee";
          user.email = "76544194+madmaxieee@users.noreply.github.com";
        };
      }
    ];
  };

  imports = [
    ./modules/dev-basic-pkgs.nix

    ./modules/fish.nix
    ./modules/zsh.nix
    ./modules/nvim.nix
    ./modules/tmux.nix

    ./modules/atuin.nix
    ./modules/zoxide.nix
    ./modules/yazi

    ./modules/git.nix
    (import ./modules/mods { provider = "gemini"; })

    ./modules/python.nix

    ./modules/gscripts.nix
  ];
}
