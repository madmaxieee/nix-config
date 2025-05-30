{ ... }: {
  programs.fish.functions.mods = {
    body = ''
      set -x GOOGLE_API_KEY (pass gemini/mods 2> /dev/null)
      set -x OPENAI_API_KEY (pass openai/mods 2> /dev/null)
      # use flash2 model because flash 2.5 is too slow
      command mods --model flash2 --topk 40 $argv
    '';
    wraps = "mods";
  };
}
