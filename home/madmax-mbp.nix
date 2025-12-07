{ config, pkgs, ... }:

{
  home.username = "madmax";
  home.homeDirectory = "/Users/madmax";

  home.packages = with pkgs; [ zig typst ];

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
      "linode" = {
        hostname = "linode.madmaxieee.dev";
        user = "madmax";
      };
      "soft" = {
        hostname = "soft.madmaxieee.dev";
        port = 23231;
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      "cthulhu" = {
        hostname = "cthulhu.ee.ntu.edu.tw";
        user = "madmax";
      };
      "athena" = {
        hostname = "athena.ee.ntu.edu.tw";
        user = "madmax";
      };
      "valkyrie" = {
        hostname = "valkyrie.ee.ntu.edu.tw";
        user = "madmax";
      };
      "zeus" = {
        hostname = "zeus.ee.ntu.edu.tw";
        user = "madmax";
      };
    };
  };

  xdg.configFile = {
    "sesh/sesh.toml".text = ''
      [[session]]
      name = "linode"
      path = "~"
      startup_command = "exec ssh linode"

      [[session]]
      name = "obsidian"
      path = "~/obsidian"
      startup_command = "exec nvim"
    '';
  };

  programs.fish.shellAbbrs = {
    d = "docker";
    dco = "docker compose";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    d = "docker";
    dco = "docker compose";
  };

  programs.git = {
    settings.user = {
      name = "madmaxieee";
      email = "76544194+madmaxieee@users.noreply.github.com";
    };
  };

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
    ./modules/go.nix
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
            message_app = "Messenger",
            browser = "Arc",
            note_app = "Heptabase",
            terminal_app = "kitty",
            ai_app = "T3 Chat",
        }
      '';
    })

    ./modules/jujutsu.nix
  ];

}
