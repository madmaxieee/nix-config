{ config, lib, pkgs, ... }:

{
  home.packages = [ ];

  home.activation = let git = "${pkgs.git}/bin/git";
  in {
    clone_nvim_config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${config.xdg.configHome}/nvim ]; then
        $DRY_RUN_CMD ${git} clone https://github.com/madmaxieee/nvim-config.git ${config.xdg.configHome}/nvim
      fi
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraLuaPackages = ps: with ps; [ sqlite luv magick ];
    extraPackages = with pkgs;
      [
        cargo
        nodejs_20
        go

        nixfmt-classic
        nil

        sqlite
        imagemagick
      ] ++ (if stdenv.isDarwin then
        [
          # for obsidian.nvim, ObsidianPasteImg
          pngpaste
        ]
      else
        [ ]);
  };
  home.sessionVariables = if pkgs.stdenv.isDarwin then {
    # for sqlite.lua on macos
    "LIBSQLITE" = "${pkgs.sqlite.out}/lib/libsqlite3.dylib";
  } else
    { };

  programs.fish.shellAbbrs = {
    nv = "nvim";
    v = "nvim";
    vi = "nvim";
  };
}
