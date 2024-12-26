{ ... }: {
  programs.fish.functions.mods = {
    body = ''
      set -x GOOGLE_API_KEY (pass gemini/mods 2> /dev/null)
      command mods --model flash --topk 40 $argv
    '';
    wraps = "mods";
  };
}
