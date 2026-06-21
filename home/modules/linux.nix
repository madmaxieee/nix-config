{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.fish = {
    shellAbbrs.hm = lib.mkDefault "home-manager";
  };
  programs.zsh = {
    zsh-abbr.abbreviations.hm = lib.mkDefault "home-manager";
  };

  home.sessionVariables = {
    # make other programs aware of terminfos of terminals installed by home manager
    TERMINFO_DIRS = "${config.home.profileDirectory}/share/terminfo:/usr/share/terminfo";
  };

  # needed for nix.settings to work
  nix.package = pkgs.nix;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    download-buffer-size = 512 * 1024 * 1024;
    auto-optimise-store = true;
  };
}
