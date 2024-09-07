{ lib, fetchFromGitHub, pkgs }:

pkgs.lua54Packages.buildLuaPackage {
  name = "SbarLua";
  pname = "SbarLua";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "FelixKratz";
    repo = "SbarLua";
    rev = "437bd2031da38ccda75827cb7548e7baa4aa9978";
    hash = "sha256-F0UfNxHM389GhiPQ6/GFbeKQq5EvpiqQdvyf7ygzkPg=";
  };

  buildInputs = with pkgs; [
    gcc
    darwin.apple_sdk.frameworks.CoreFoundation
    readline
  ];

  installPhase = ''
    mkdir -p $out/lib/lua/5.4
    cp ./bin/sketchybar.so $out/lib/lua/5.4
  '';

  meta = with lib; {
    description = "SketchyBar Lua Plugin";
    homepage = "https://github.com/FelixKratz/SbarLua";
    platforms = platforms.darwin;
  };
}
