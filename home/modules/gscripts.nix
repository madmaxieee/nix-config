{ config, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  home.file = {
    ".local/bin/gob-create".source = linkDotfile "gscripts/gob-create";
    ".local/bin/gerrit-init".source = linkDotfile "gscripts/gerrit-init";
    ".local/bin/x20-share".source = linkDotfile "gscripts/x20-share";
  };
}
