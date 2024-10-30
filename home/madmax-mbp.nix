{ config, ... }:

{
  home.username = "madmax";
  home.homeDirectory = "/Users/madmax";

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
    y = "yarn";
    pm = "pnpm";
    n = "npm";
    gr = "gradle";
    grr = "gradle -q --console plain run";
  };

  programs.git = {
    userName = "madmaxieee";
    userEmail = "76544194+madmaxieee@users.noreply.github.com";
  };

  imports = [
    ./modules/mac.nix

    ./modules/fish.nix
    ./modules/zsh.nix
    ./modules/nvim.nix
    ./modules/tmux.nix

    ./modules/atuin.nix
    ./modules/zoxide.nix

    ./modules/git.nix
    ./modules/mods.nix

    ./modules/python.nix

    # ./modules/scripts.nix

    (import ./modules/window-management.nix {
      hs_extra_config = ''
        return {
            message_app = "Messenger",
            browser = "Arc",
        }
      '';
    })
  ];

}
