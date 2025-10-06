{ config, pkgs, sources, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  home.packages = with pkgs; [ fd ripgrep ripgrep-all glow lazygit ouch ];

  xdg.configFile = {
    "yazi/init.lua".source = linkDotfile "yazi/init.lua";
    "yazi/keymap.toml".source = linkDotfile "yazi/keymap.toml";
    "yazi/yazi.toml".source = linkDotfile "yazi/yazi.toml";
  };

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    plugins = {
      git = "${sources.yazi-plugins}/git.yazi";
      smart-enter = "${sources.yazi-plugins}/smart-enter.yazi";
      lazygit = sources.lazygit-yazi;
      searchjump = sources.searchjump-yazi;
      what-size = sources.what-size-yazi;
      ouch = sources.ouch-yazi;
    };
  };
}
