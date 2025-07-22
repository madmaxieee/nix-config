{ config, pkgs, ... }:

{
  home.username = "maxcchuang";
  home.homeDirectory = "/Users/maxcchuang";

  home.packages = with pkgs; [ minicom d2 vscode ];

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
        localForwards = [{
          host.address = "127.0.0.1";
          host.port = 5000;
          bind.address = "127.0.0.1";
          bind.port = 5000;
        }];
        extraOptions = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/ctrl-%C";
          ControlPersist = "yes";
        };
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
      startup_command = "cloudtop --exec maxcchuang.c"

      [[session]]
      name = "obsidian"
      path = "~/obsidian"
      startup_command = "exec nvim"
    '';
  };

  programs.fish.functions = {
    cloudtop = ''
      if test \( (count $argv) -gt 1 \) -a \( "$argv[1]" = --exec \)
          set -f exec_cmd exec
          set -f ssh_host $argv[2]
      else
          set -f exec_cmd ""
          set -f ssh_host $argv[1]
      end

      if type -q rw
          set -f ssh_command "rw --check_remaining"
      else
          echo "roadwarrior not found, using ssh"
          set -f ssh_command ssh
      end

      eval "$exec_cmd $ssh_command $ssh_host"
    '';
  };

  programs.fish.shellAbbrs = { ct = "cloudtop maxcchuang.c"; };

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
    # my GCP project got suspended
    (import ./modules/mods { provider = "gemini"; })

    ./modules/clang-tools.nix
    ./modules/python.nix
    ./modules/java.nix

    (import ./modules/window-management.nix {
      hs_extra_config = ''
        local scratchpad = require("scratchpad")
        scratchpad.hide_on_cmd_w("Chrome Remote Desktop")
        scratchpad.hide_on_cmd_w("Lucid")

        return {
            message_app = "Google Chat",
            browser = "Google Chrome",
            note_app = "Obsidian",
            terminal_app = "kitty",
            ai_app = "Gemini",
        }
      '';
    })

    ./modules/mprocs.nix
  ];
}
