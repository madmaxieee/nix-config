{ pkgs, ... }: {
  home.packages = with pkgs; [
    clang
    clang-tools

    gnumake
    cmake
  ];
}
