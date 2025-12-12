{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.yabai ];

  services.skhd = { enable = true; };

  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    package = pkgs.yabai;
  };
}
