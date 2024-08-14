{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.nixfmt-classic pkgs.sqlite ];

  home.activation = let git = "${pkgs.git}/bin/git";
  in {
    clone_nvim_config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${config.xdg.configHome}/nvim ]; then
        ${git} clone https://github.com/madmaxieee/nvim-config.git ${config.xdg.configHome}/nvim
      fi
    '';
  };

  programs.neovim = {
    enable = true;
    extraLuaPackages = ps: with ps; [ sqlite luv magick ];
  };
  home.sessionVariables = {
    # for sqlite.lua
    "LIBSQLITE" = "${pkgs.sqlite.out}/lib/libsqlite3.dylib";
  };
}