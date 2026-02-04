{ config, pkgs, ... }:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.username = "maxcchuang";
  home.homeDirectory = "/Users/maxcchuang";

  home.packages = with pkgs; [
    minicom
    d2
  ];

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
        # for remote sesh service
        localForwards = [
          {
            host.address = "127.0.0.1";
            host.port = 8080;
            bind.address = "127.0.0.1";
            bind.port = 8080;
          }
        ];
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "yes";
        proxyCommand = "corp-ssh-helper -relay=sup-ssh-relay.corp.google.com --proxy-mode=grue --vmodule=grue_transport=1 -dst_username=%r %h %p";
      };
      "auto gcert" = {
        match = ''host *.c.googlers.com exec  "find /var/run/ccache/sso-$USER/cookie ~/.sso/cookie -mmin -1200 2>/dev/null | grep -q . && gcertstatus --check_remaining=1h --nocheck_loas2 --quiet || gcert --noloas2"'';
      };
    };
  };

  xdg.configFile = {
    "sesh/sesh.toml".source = linkDotfile "sesh/sesh-maxcchuang-mac.toml";
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

      if type -q autogcert
        autogcert $ssh_host
      end

      eval "$exec_cmd caffeinate -i ssh $ssh_host"
    '';
  };

  programs.fish.shellAbbrs = {
    a = "adb";
    al = "adb logcat";
    ar = "adb root";
    arr = "adb reboot";
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
            terminal_app = "kitty",
            ai_app = "Google Gemini",
        }
      '';
    })

    ./modules/jujutsu.nix

    ./modules/git-google.nix
    ./modules/mprocs.nix
  ];
}
