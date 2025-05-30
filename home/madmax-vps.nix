{ pkgs, ... }:

{
  home.username = "madmax";
  home.homeDirectory = "/home/madmax";

  home.packages = with pkgs; [
    kitty
    rustup
    typst
    zig
    llvmPackages_18.libcxxClang
  ];

  programs.fish = {
    shellAbbrs = {
      copy = "kitten clipboard";
      paste = "kitten clipboard -g";
    };
  };

  programs.zsh = {
    zsh-abbr.abbreviations = {
      copy = "kitten clipboard";
      paste = "kitten clipboard -g";
    };
  };

  imports = [
    ./modules/home-manager.nix
    ./modules/dev-basic-pkgs.nix

    ./modules/fish.nix
    ./modules/zsh.nix
    ./modules/nvim.nix
    ./modules/tmux.nix

    ./modules/scripts.nix

    ./modules/atuin.nix
    ./modules/zoxide.nix
    ./modules/yazi

    ./modules/git.nix
    (import ./modules/mods { provider = "gemini"; })

    ./modules/clang-tools.nix
    ./modules/python.nix
    ./modules/java.nix
    ./modules/web-dev.nix

    ./modules/moar.nix
    ./modules/jujutsu.nix
  ];
}
