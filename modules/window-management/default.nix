{ pkgs, ... }:

let sbarLua = pkgs.callPackage ./SbarLua.nix { };
in {
  environment.systemPackages = [ pkgs.yabai ];
  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    package = pkgs.yabai;
  };
  services.skhd = { enable = true; };
  services.jankyborders = {
    enable = true;
    active_color = "0xaae1e3e4";
    inactive_color = "0x00494d64";
    width = 3.0;
  };
  services.sketchybar = {
    enable = true;
    extraPackages =
      [ (pkgs.lua54Packages.lua.withPackages (ps: [ sbarLua ])) pkgs.jq ];
  };

  homebrew.casks = [ "hammerspoon" ];

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono pkgs.sketchybar-app-font ];
}
