{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
      clang-tools
      cmake
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ gnumake ];
}
