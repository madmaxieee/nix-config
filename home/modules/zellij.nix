{
  config,
  pkgs,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
rec {
  home.packages = with pkgs; [ zellij ];

  xdg.configFile = {
    "zellij".source = linkDotfile "zellij";
  };

  programs.fish = {
    shellAbbrs = {
      zl = "zellij";
    };
  };

  programs.zsh = {
    zsh-abbr.abbreviations = programs.fish.shellAbbrs;
  };
}
