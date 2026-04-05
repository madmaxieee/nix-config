{ config, ... }:
{
  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];

  programs.bacon.enable = true;

  programs.mise = {
    globalConfig.tools = {
      rust = "nightly";
    };
  };

  imports = [
    ./mise.nix
  ];
}
