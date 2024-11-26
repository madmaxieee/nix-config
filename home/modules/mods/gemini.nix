{ ... }: {
  programs.fish.functions.mods = {
    body = ''
      set -x GOOGLE_API_KEY (pass gemini/mods 2> /dev/null)
      command mods --model gemini $argv
    '';
    wraps = "mods";
  };
}
