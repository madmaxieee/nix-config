{ pkgs, ... }: {
  home.packages = with pkgs; [ moar ];
  home.sessionVariables = {
    PAGER = "moar";
    MOAR = "-quit-if-one-screen";
  };
}
