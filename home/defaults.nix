{ config, lib, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.activation = let git = "${pkgs.git}/bin/git";
  in {
    clone_dotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${nix_config_path} ]; then
        ${git} clone https://github.com/madmaxieee/nix-config.git ${nix_config_path}
      fi
    '';
    clone_nvim_config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${config.xdg.configHome}/nvim ]; then
        ${git} clone https://github.com/madmaxieee/nvim-config.git ${config.xdg.configHome}/nvim
      fi
    '';
  };

  # Packages that should be installed to the user profile.
  home.packages = [ ];

  home.file = {
    ".config/starship.toml".source = linkDotfile "starship/starship.toml";
    ".gitconfig".source = linkDotfile "git/gitconfig";
    ".gitignore".source = linkDotfile "git/gitignore";
    ".config/kitty".source = linkDotfile "kitty";
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

  programs.poetry.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
