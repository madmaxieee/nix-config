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
      "*.c" = {
        hostname = "%h.googlers.com";
        forwardAgent = true;
      };
    };
  };

  imports = [
    ./modules/mac.nix

    ./modules/fish.nix
    ./modules/zsh.nix
    ./modules/nvim.nix
    ./modules/tmux.nix

    ./modules/atuin.nix
    ./modules/zoxide.nix

    ./modules/git-google.nix

    ./modules/window-management.nix

    ./modules/python.nix

    ./modules/scripts.nix
  ];

}
