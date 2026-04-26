{ profile }:
{
  config,
  lib,
  pkgs,
  sources,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
  axon = pkgs.callPackage ../../packages/axon.nix { };
in
{
  home.packages = with pkgs; [
    axon
    glow
  ];

  xdg.configFile = {
    "axon/axon.toml".source = linkDotfile "axon/axon.toml";
    "axon/prompts".source = linkDotfile "axon/prompts";
    "axon/fabric_prompts".source = "${sources.fabric}/data/patterns";
    "axon/conf.d/models.toml".source = linkDotfile "axon/conf.d/models-${profile}.toml";
  };

  imports = [
    ./password-store.nix
  ];
}
