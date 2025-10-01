{ config, pkgs, lib, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
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
