{ config, pkgs, ... }:

{
  home.username = "madmax";
  home.homeDirectory = "/Users/madmax";

  home.packages = with pkgs;
    [
      # FIX: zig build is broken as of 2024/11/05
      # zig
      rustup
    ];

  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];

  programs.ssh = {
    enable = true;
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

  programs.fish.shellAbbrs = {
    d = "docker";
    dco = "docker compose";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    d = "docker";
    dco = "docker compose";
  };

  programs.git = {
    userName = "madmaxieee";
    userEmail = "76544194+madmaxieee@users.noreply.github.com";
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
    ./modules/yazi.nix

    ./modules/git.nix
    ./modules/mods.nix

    ./modules/python.nix
    ./modules/java.nix
    ./modules/web-dev.nix

    (import ./modules/window-management.nix {
      hs_extra_config = ''
        return {
            message_app = "Messenger",
            browser = "Arc",
            note_app = "Heptabase",
        }
      '';
    })
  ];

}
