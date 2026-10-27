{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.aerospace ];
  homebrew.casks = [ "mediosz/tap/swipeaerospace" ];
  system.defaults.dock.expose-group-apps = true;
}
