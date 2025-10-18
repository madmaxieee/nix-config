{ config, pkgs, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  home.packages = with pkgs; [ jujutsu ];
  home.sessionVariables.JJ_CONFIG = "${config.xdg.configHome}/jj/config.toml";
  xdg.configFile = {
    "jj" = {
      source = linkDotfile "jujutsu";
      recursive = false;
    };
  };

  # jj breaks common pager like less or more, so use moar instead
  imports = [ ./moar.nix ];
}
