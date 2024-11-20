{ ... }: {
  programs.fish.functions.mods = {
    body = ''
      set -x GOOGLE_API_KEY (pass gemini/mods)
      command mods --model gemini $argv
    '';
    wraps = "mods";
  };
}
