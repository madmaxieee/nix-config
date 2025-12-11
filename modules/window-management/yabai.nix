{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.yabai ];

  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    package = pkgs.yabai;
  };
}
