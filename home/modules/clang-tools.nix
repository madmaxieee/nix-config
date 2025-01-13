{ pkgs, ... }: {
  home.packages = with pkgs; [
    clang-tools

    gnumake
    cmake
  ];
}
