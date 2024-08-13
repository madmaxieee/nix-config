{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "madmax";
  home.homeDirectory = "/Users/madmax";

  # Packages that should be installed to the user profile.
  home.packages = [ ];
  home.file = {
    ".config/starship.toml".source = ../dotfiles/starship/starship.toml;
    ".gitconfig".source = ../dotfiles/git/gitconfig;
    ".gitignore".source = ../dotfiles/git/gitignore;
    ".config/kitty".source = ../dotfiles/kitty;
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
