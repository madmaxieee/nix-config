{ config, pkgs, ... }: {
  home.packages = with pkgs; [ mods pass gnupg ];

  programs.fish.functions.modsq = ''
    set -x OPENAI_API_KEY (pass openai/mods)
    mods $argv
  '';
}
