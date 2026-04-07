{ config, ... }:
{
  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];

  home.file = {
    ".cargo/config.toml".text = ''
      [net]
      git-fetch-with-cli = true
    '';
  };

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
