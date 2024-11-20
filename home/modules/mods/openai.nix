{ ... }: {
  programs.fish.functions.mods = {
    body = ''
      set -x OPENAI_API_KEY (pass openai/mods)
      command mods --model gpt-4o $argv
    '';
    wraps = "mods";
  };
}
