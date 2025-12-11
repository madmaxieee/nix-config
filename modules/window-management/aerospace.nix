{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.aerospace ];

  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;
  };
}
