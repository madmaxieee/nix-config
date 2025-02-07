{ ... }: {
  programs.fish.functions.mods = {
    body = ''
      set -x OPENAI_API_KEY (pass openai/mods 2> /dev/null)
      command mods --model gpt-4o-mini $argv
    '';
    wraps = "mods";
  };
}
