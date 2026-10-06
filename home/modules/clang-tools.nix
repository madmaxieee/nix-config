{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
      clang-tools
      cmake
    ]
    ++ lib.optionals stdenv.isLinux [ gnumake ];
}
