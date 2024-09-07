{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
  sbarLua = pkgs.callPackage ./SbarLua.nix { };
in {
  home.packages = [ (pkgs.lua54Packages.lua.withPackages (ps: [ sbarLua ])) ];

  xdg.configFile = {
    "sketchybar" = {
      source = linkDotfile "sketchybar";
      recursive = false;
    };
  };
}
