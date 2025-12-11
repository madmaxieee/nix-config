{ wm ? "yabai" }:
{ pkgs, ... }:

let sbarLua = pkgs.callPackage ./SbarLua.nix { };
in {
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
} // (if wm == "yabai" then
  (import ./yabai.nix { inherit pkgs; })
else if wm == "aerospace" then
  (import ./aerospace.nix { inherit pkgs; })
else
  throw "Unsupported window manager: ${wm}")
