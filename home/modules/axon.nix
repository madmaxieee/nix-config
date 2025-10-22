{ config, lib, pkgs, ... }:

let
  linkDotfile = config.lib.custom.linkDotfile;
  fabric-repo = pkgs.fetchFromGitHub {
    owner = "danielmiessler";
    repo = "Fabric";
    rev = "0cbca8bd6abbf9053bafb934965f724af4a18c75";
    hash = "sha256-L3wRn4EQeEhl7D4kHT/CFf7ovg323yyi/tEgl5z2Ff8=";
  };
in {
  xdg.configFile = {
    "axon/axon.toml".source = linkDotfile "axon/axon.toml";
    "axon/prompts".source = linkDotfile "axon/prompts";
    "axon/fabric-prompts".source = "${fabric-repo}/data/patterns";
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
