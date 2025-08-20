{ config, platform }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  home.file = if platform == "glinux" then {
    ".local/bin/gob-create".source = linkDotfile "gscripts/gob-create";
    ".local/bin/gerrit-init".source = linkDotfile "gscripts/gerrit-init";
    ".local/bin/x20-share".source = linkDotfile "gscripts/x20-share";
  } else if platform == "gmac" then {
    ".local/bin/fetch-artifact".source = linkDotfile "gscripts/fetch-artifact";
  } else
    (throw ("gscripts: platform must be one of glinux or gmac"));
}
