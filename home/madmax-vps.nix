{ pkgs, ... }:

{
  home.username = "madmax";
  home.homeDirectory = "/home/madmax";

  home.packages = with pkgs; [
    # for terminfo
    ghostty
    kitty
  ];

  imports = [
    ./lib.nix

    ./modules/linux.nix
    ./modules/dev-basic-pkgs.nix

    ./modules/fish.nix
    ./modules/nvim.nix
    ./modules/tmux.nix

    ./modules/scripts.nix

    ./modules/atuin.nix
    ./modules/zoxide.nix
    ./modules/yazi.nix

    ./modules/git.nix

    ./modules/java.nix
  ];
}
