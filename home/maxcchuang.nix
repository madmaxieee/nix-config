{ config, lib, pkgs, ... }:

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
    };
  };

  # must sudo explicitly, the sudoer file does not work on this machine
  home.activation = let yabai = "${pkgs.yabai}/bin/yabai";
  in {
    load_yabai_sa = lib.hm.dag.entryAfter [ "writeBoundary" ]
      "$DRY_RUN_CMD /usr/bin/sudo ${yabai} --load-sa";
  };

  imports = [ ./defaults.nix ];
}
