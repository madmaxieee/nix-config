{ config, pkgs, ... }:

{
  home.username = "maxcchuang";
  home.homeDirectory = "/Users/maxcchuang";

  home.packages = with pkgs; [ minicom d2 ];

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "soft" = {
        hostname = "soft.madmaxieee.dev";
        port = 23231;
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      "*.c" = {
        hostname = "%h.googlers.com";
        forwardAgent = true;
      };
      "auto gcert" = {
        match = ''
          host *.c.googlers.com exec  "find /var/run/ccache/sso-$USER/cookie ~/.sso/cookie -mmin -1200 2>/dev/null | grep -q . && gcertstatus --check_remaining=1h --nocheck_loas2 --quiet || gcert --noloas2"'';
      };
    };
  };

  xdg.configFile = {
    "sesh/sesh.toml".text = ''
      [[session]]
      name = "cloud"
      path = "~"
      startup_command = "TERM=xterm-256color exec ssh maxcchuang.c"

      [[session]]
      name = "obsidian"
      path = "~/obsidian"
      startup_command = "exec nvim"
    '';
  };

  programs.git = {
    userName = "maxcchuang";
    userEmail = "maxcchuang@google.com";
    extraConfig = {
      http.cookiefile = "${config.home.homeDirectory}/.gitcookies";
    };
  };

  imports = [
    ./modules/mac.nix
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

    ./modules/clang.nix
    ./modules/python.nix
    ./modules/java.nix

    (import ./modules/window-management.nix {
      hs_extra_config = ''
        return {
            message_app = "Google Chat",
            browser = "Google Chrome",
            note_app = "Obsidian",
        }
      '';
    })
  ];
}
