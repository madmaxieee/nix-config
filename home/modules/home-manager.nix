{ lib, ... }:

{
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.fish = { shellAbbrs.hm = lib.mkDefault "home-manager"; };
  programs.zsh = { zsh-abbr.abbreviations.hm = lib.mkDefault "home-manager"; };

  xdg.configFile = {
    "nix/nix.conf".text = ''
      extra-experimental-features = nix-command flakes
    '';
  };
}
