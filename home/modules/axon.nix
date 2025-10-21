{ config, pkgs, ... }:

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
      set -x OPENAI_API_KEY (pass openai/mods 2> /dev/null)
      set -x ANTHROPIC_API_KEY (pass anthropic/mods 2> /dev/null)
      go run github.com/madmaxieee/axon@latest $argv
    '';
    interactiveShellInit = ''
      axon completion fish | source
    '';
  };

  imports = [ ./password-store.nix ./go.nix ];
}
