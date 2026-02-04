{ provider }:
{
  config,
  pkgs,
  lib,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.packages = with pkgs; [ mods ];

  xdg.configFile."mods".source = linkDotfile "mods";

  programs.fish.functions.mods = {
    body =
      if provider == "openai" then
        ''
          set -x GOOGLE_API_KEY (pass gemini/mods 2> /dev/null)
          set -x OPENAI_API_KEY (pass openai/mods 2> /dev/null)
          set -x ANTHROPIC_API_KEY (pass anthropic/mods 2> /dev/null)
          command mods --model gpt-4o-mini $argv
        ''
      else if provider == "gemini" then
        ''
          set -x GOOGLE_API_KEY (pass gemini/mods 2> /dev/null)
          set -x OPENAI_API_KEY (pass openai/mods 2> /dev/null)
          set -x ANTHROPIC_API_KEY (pass anthropic/mods 2> /dev/null)
          command mods --model flash2 --topk 40 $argv
        ''
      else
        (throw ("mods: provider must be one of openai or gemini"));
  };

  imports = [ ./password-store.nix ];
}
