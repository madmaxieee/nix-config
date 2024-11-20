{ ... }: {
  programs.fish.functions.mods = {
    body = ''
      set -x OPENAI_API_KEY (pass openai/mods)
      command mods --model gemini $argv
    '';
    wraps = "mods";
  };
}
