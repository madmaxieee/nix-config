{ config, pkgs, ... }:

{
  home.username = "maxcchuang";
  home.homeDirectory = "/Users/maxcchuang";

  home.packages = with pkgs; [ minicom d2 ];

  # former default options
  programs.ssh.matchBlocks."*" = {
    forwardAgent = false;
    addKeysToAgent = "no";
    compression = false;
    serverAliveInterval = 0;
    serverAliveCountMax = 3;
    hashKnownHosts = false;
    userKnownHostsFile = "~/.ssh/known_hosts";
    controlMaster = "no";
    controlPath = "~/.ssh/master-%r@%n:%p";
    controlPersist = "no";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
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

      eval "$exec_cmd caffeinate -i ssh $ssh_host"
    '';
  };

  programs.fish.shellAbbrs = {
    a = "adb";
    ar = "adb reboot";
    arb = "adb reboot bootloader";
    as = "adb shell";
    aw = "adb wait-for-device";
    f = "fastboot";
    fr = "fastboot reboot";
    frb = "fastboot reboot bootloader";
  };

  home.sessionPath = [ "/usr/local/git/git-google/bin" ];

  imports = [
    ./lib.nix

    ./modules/mac.nix
    ./modules/dev-basic-pkgs.nix

    ./modules/fish.nix
    ./modules/zsh.nix
    ./modules/nvim.nix
    ./modules/tmux.nix

    ./modules/scripts.nix

    ./modules/atuin.nix
    ./modules/zoxide.nix
    ./modules/yazi.nix
    ./modules/television.nix

    ./modules/git.nix

    ./modules/clang-tools.nix
    ./modules/java.nix
    ./modules/python.nix
    ./modules/rust.nix
    ./modules/web-dev.nix

    (import ./modules/mods.nix { provider = "gemini"; })
    ./modules/axon.nix
    ./modules/fabric-ai.nix
    ./modules/gemini-cli.nix
    ./modules/opencode.nix

    (import ./modules/window-management.nix {
      hs_extra_config = ''
        return {
            message_app = "Google Chat",
            browser = "Google Chrome",
            note_app = "Obsidian",
            terminal_app = "kitty",
            ai_app = "T3 Chat",
        }
      '';
    })

    ./modules/jujutsu.nix

    ./modules/git-google.nix
    ./modules/mprocs.nix
  ];
}
