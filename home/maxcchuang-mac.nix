{ config, ... }:

{
  home.username = "maxcchuang";
  home.homeDirectory = "/Users/maxcchuang";

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "soft" = {
        hostname = "soft.madmaxieee.dev";
        port = 23231;
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      "cloudtop" = {
        hostname = "maxcchuang.c.googlers.com";
        forwardAgent = true;
      };
    };
  };

  imports = [ ./mac.nix ./modules/git-google.nix ];
}
