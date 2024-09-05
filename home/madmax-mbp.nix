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

  imports = [ ./mac.nix ./modules/git.nix ./modules/mods.nix ];
}
