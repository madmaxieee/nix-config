{ pkgs, ... }:

let
  fabric-repo = pkgs.fetchFromGitHub {
    owner = "danielmiessler";
    repo = "Fabric";
    rev = "0cbca8bd6abbf9053bafb934965f724af4a18c75";
    hash = "sha256-L3wRn4EQeEhl7D4kHT/CFf7ovg323yyi/tEgl5z2Ff8=";
  };
in {
  home.packages = with pkgs; [ fabric-ai ];

  xdg.configFile = {
    "fabric/.env".text = ''
      DEFAULT_VENDOR=Gemini
      DEFAULT_MODEL=gemini-2.5-flash
      PATTERNS_LOADER_GIT_REPO_URL=https://github.com/danielmiessler/fabric.git
      PATTERNS_LOADER_GIT_REPO_PATTERNS_FOLDER=data/patterns
      PROMPT_STRATEGIES_GIT_REPO_URL=https://github.com/danielmiessler/fabric.git
      PROMPT_STRATEGIES_GIT_REPO_STRATEGIES_FOLDER=data/strategies
    '';
    "fabric/patterns".source = "${fabric-repo}/data/patterns";
    "fabric/strategies".source = "${fabric-repo}/data/strategies";
    "fish/completions/fabric.fish".source =
      "${fabric-repo}/completions/fabric.fish";
  };

  programs.fish.functions.fabric = {
    body = ''
      set -x GEMINI_API_KEY (pass gemini/cli 2> /dev/null)
      command fabric $argv
    '';
    wraps = "fabric";
  };

  imports = [ ./password-store.nix ];
}
