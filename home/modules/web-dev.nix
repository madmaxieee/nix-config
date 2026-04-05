{ lib, ... }:
rec {
  programs.fish.shellAbbrs = {
    b = lib.mkDefault "bun";
    br = lib.mkDefault "bun run";
    pm = lib.mkDefault "pnpm";
  };

  programs.zsh.zsh-abbr.abbreviations = programs.fish.shellAbbrs;

  programs.mise = {
    globalConfig.tools = {
      bun = "latest";
      node = {
        version = "lts";
        postinstall = "corepack enable";
      };
    };
  };

  imports = [
    ./mise.nix
  ];
}
