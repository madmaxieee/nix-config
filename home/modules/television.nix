{ config, ... }:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  xdg.configFile = {
    "television/config.toml".source = linkDotfile "television/config.toml";
  };

  home.file = {
    ".local/bin/tv-tmux".source = linkDotfile "television/tv-tmux";
  };

  programs.television = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
    enableFishIntegration = false;
  };
}
