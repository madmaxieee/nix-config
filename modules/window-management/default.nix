{
  wm ? "yabai",
}:
{ pkgs, lib, ... }:

{
  imports =
    lib.optional (wm == "yabai") ./yabai.nix ++ lib.optional (wm == "aerospace") ./aerospace.nix;

  environment.systemPackages = [ pkgs.sketchybar ];

  services.jankyborders = {
    enable = true;
    active_color = "0xaae1e3e4";
    inactive_color = "0x00494d64";
    width = 3.0;
  };

  services.sketchybar = {
    enable = true;
    package = pkgs.sketchybar;
    extraPackages = [
      (pkgs.lua55Packages.lua.withPackages (ps: [ pkgs.sbarlua ]))
      pkgs.jq
    ];
  };

  homebrew.casks = [ "hammerspoon" ];

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.sketchybar-app-font
  ];
}
