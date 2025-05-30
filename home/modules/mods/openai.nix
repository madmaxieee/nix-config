{ ... }: {
  programs.fish.functions.mods = {
    body = ''
      set -x GOOGLE_API_KEY (pass gemini/mods 2> /dev/null)
      set -x OPENAI_API_KEY (pass openai/mods 2> /dev/null)
      command mods --model gpt-4o-mini $argv
    '';
    wraps = "mods";
  };
}
