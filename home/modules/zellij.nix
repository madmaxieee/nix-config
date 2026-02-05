{
  config,
  pkgs,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.packages = with pkgs; [ zellij ];

  xdg.configFile = {
    "zellij".source = linkDotfile "zellij";
  };
}
