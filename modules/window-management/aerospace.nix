{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.aerospace ];
  homebrew.casks = [ "mediosz/tap/swipeaerospace" ];
}
