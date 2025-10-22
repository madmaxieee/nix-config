{ config, lib, pkgs, sources, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  xdg.configFile = {
    "axon/axon.toml".source = linkDotfile "axon/axon.toml";
    "axon/prompts".source = linkDotfile "axon/prompts";
    "axon/fabric_prompts".source = "${sources.fabric}/data/patterns";
  };

  programs.fish = {
    functions.axon.body = ''
      set -x GOOGLE_API_KEY (pass gemini/cli 2> /dev/null)
      command axon $argv
    '';
  };

  home.activation = let go = "${pkgs.go}/bin/go";
  in {
    axon_install = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${go} install github.com/madmaxieee/axon@latest
      run ${config.home.homeDirectory}/go/bin/axon completion fish > ${config.xdg.configHome}/fish/completions/axon.fish
    '';
  };

  imports = [ ./password-store.nix ./go.nix ];
}
