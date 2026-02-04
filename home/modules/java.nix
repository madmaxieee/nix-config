{ lib, ... }:
{
  programs.java.enable = true;
  programs.gradle.enable = true;

  programs.fish.shellAbbrs = {
    gr = lib.mkDefault "gradle";
    grr = lib.mkDefault "gradle -q --console plain run";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    gr = lib.mkDefault "gradle";
    grr = lib.mkDefault "gradle -q --console plain run";
  };
}
