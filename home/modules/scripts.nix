{ config, pkgs, lib, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.file = lib.mkMerge [
    {
      ".local/bin/git-foreach".source = linkDotfile "scripts/git-foreach";
      ".local/bin/nr".source = linkDotfile "scripts/nr";
      ".local/bin/ns".source = linkDotfile "scripts/ns";
      ".local/bin/vipe".source = linkDotfile "scripts/vipe";
    }

    (lib.mkIf pkgs.stdenv.isDarwin {
      ".local/bin/things".source = linkDotfile "scripts/things";
    })
  ];
}
