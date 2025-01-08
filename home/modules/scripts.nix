{ config, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  home.file = {
    ".local/bin/vipe".source = linkDotfile "scripts/vipe";
    ".local/bin/ns".source = linkDotfile "scripts/ns";
    ".local/bin/nr".source = linkDotfile "scripts/nr";
  };
}
