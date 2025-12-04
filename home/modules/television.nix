{ config, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  xdg.configFile = {
    "television/config.toml".source = linkDotfile "television/config.toml";
  };

  programs.television.enable = true;
}
