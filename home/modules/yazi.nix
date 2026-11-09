{
  config,
  pkgs,
  sources,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.packages = with pkgs; [
    fd
    ripgrep
    lazygit
    ouch
    television
  ];

  xdg.configFile = {
    "yazi/init.lua".source = linkDotfile "yazi/init.lua";
    "yazi/keymap.toml".source = linkDotfile "yazi/keymap.toml";
    "yazi/yazi.toml".source = linkDotfile "yazi/yazi.toml";
    # vendored from github:DreamMaoMao/searchjump.yazi (unmaintained), ported to ya.emit
    "yazi/plugins/searchjump.yazi".source = linkDotfile "yazi/plugins/searchjump.yazi";
  };

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    plugins = {
      git = "${sources.yazi-plugins}/git.yazi";
      smart-enter = "${sources.yazi-plugins}/smart-enter.yazi";
      types = "${sources.yazi-plugins}/types.yazi";
      lazygit = sources.lazygit-yazi;
      what-size = sources.what-size-yazi;
      ouch = sources.ouch-yazi;
      tv = sources.tv-yazi;
    };
  };
}
