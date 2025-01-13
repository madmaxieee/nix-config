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
      startup_command = "exec ssh maxcchuang.c"

      [[session]]
      name = "obsidian"
      path = "~/obsidian"
      startup_command = "exec nvim"
    '';
  };

  programs.fish.shellAbbrs = { ss = "ssh maxcchuang.c"; };

  programs.zsh.zsh-abbr.abbreviations = { ss = "ssh maxcchuang.c"; };

  home.sessionPath = [ "/usr/local/git/git-google/bin" ];

  imports = [
    ./modules/mac.nix
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

    ./modules/clang-tools.nix
    ./modules/python.nix
    ./modules/java.nix

    (import ./modules/window-management.nix {
      hs_extra_config = ''
        local scratchpad = require("scratchpad")
        scratchpad.hide_on_cmd_w("Gemini")
        scratchpad.hide_on_cmd_w("Chrome Remote Desktop")
        scratchpad.hide_on_cmd_w("Lucid")

        return {
            message_app = "Google Chat",
            browser = "Google Chrome",
            note_app = "Obsidian",
            terminal_app = "kitty",
        }
      '';
    })

    ./modules/mprocs.nix
  ];
}
