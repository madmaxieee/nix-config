{ config, ... }:
{
  home.sessionPath = [ "${config.home.homeDirectory}/go/bin" ];
  programs.go.enable = true;
}
