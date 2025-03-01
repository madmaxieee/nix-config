{ ... }:

{
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.fish = { shellAbbrs.hm = "home-manager"; };
  programs.zsh = { zsh-abbr.abbreviations.hm = "home-manager"; };
}
