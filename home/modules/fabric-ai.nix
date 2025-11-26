{ pkgs, sources, ... }:

{
  home.packages = with pkgs; [ fabric-ai ];

  xdg.configFile = {
    "fabric/.env".text = ''
      DEFAULT_VENDOR=Gemini
      DEFAULT_MODEL=gemini-flash-latest
      PATTERNS_LOADER_GIT_REPO_URL=https://github.com/danielmiessler/fabric.git
      PATTERNS_LOADER_GIT_REPO_PATTERNS_FOLDER=data/patterns
      PROMPT_STRATEGIES_GIT_REPO_URL=https://github.com/danielmiessler/fabric.git
      PROMPT_STRATEGIES_GIT_REPO_STRATEGIES_FOLDER=data/strategies
    '';
    "fabric/patterns".source = "${sources.fabric}/data/patterns";
    "fabric/strategies".source = "${sources.fabric}/data/strategies";
    "fish/completions/fabric.fish".source =
      "${sources.fabric}/completions/fabric.fish";
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
