{ config, ... }:

{
  config.lib.custom = {
    nixConfigPath = "${config.home.homeDirectory}/nix-config";
    linkDotfile =
      path: config.lib.file.mkOutOfStoreSymlink "${config.lib.custom.nixConfigPath}/dotfiles/${path}";
  };
}
