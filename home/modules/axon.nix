{
  config,
  lib,
  pkgs,
  sources,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.packages = with pkgs; [ glow ];

  xdg.configFile = {
    "axon/axon.toml".source = linkDotfile "axon/axon.toml";
    "axon/prompts".source = linkDotfile "axon/prompts";
    "axon/fabric_prompts".source = "${sources.fabric}/data/patterns";
  };

  home.activation =
    let
      go = "${pkgs.go}/bin/go";
    in
    {
      # can't find gcc in this environment
      axon_install = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CGO_ENABLED=0 run ${go} install github.com/madmaxieee/axon@latest
        run ${config.home.homeDirectory}/go/bin/axon completion fish > ${config.xdg.configHome}/fish/completions/axon.fish
      '';
    };

  imports = [
    ./password-store.nix
    ./go.nix
  ];
}
