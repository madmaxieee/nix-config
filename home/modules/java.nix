{ ... }: {
  programs.java.enable = true;
  programs.gradle.enable = true;

  programs.fish.shellAbbrs = {
    gr = "gradle";
    grr = "gradle -q --console plain run";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    gr = "gradle";
    grr = "gradle -q --console plain run";
  };
}
