{ pkgs, ... }: {
  # the name of this program is changed to "moor" in v2
  home.packages = with pkgs; [ moar ];
  home.sessionVariables = {
    PAGER = "moar";
    MOAR = "-quit-if-one-screen";
  };
}
