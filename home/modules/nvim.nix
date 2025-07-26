{ config, lib, pkgs, ... }:

{
  home.activation = let git = "${pkgs.git}/bin/git";
  in {
    clone_nvim_config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${config.xdg.configHome}/nvim ]; then
        $DRY_RUN_CMD ${git} clone git@github.com:madmaxieee/nvim-config.git ${config.xdg.configHome}/nvim
      fi
    '';
  };

  home.packages = with pkgs; [ ripgrep fd lazygit ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraLuaPackages = ps: with ps; [ sqlite luv ];
    extraPackages = with pkgs;
      [
        cargo
        go
        nodejs_20
        python312
        unzip

        nixfmt-classic
        nil

        sqlite
        imagemagick
        ghostscript
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
    dv = "diffview";
  };
  programs.fish.functions = { diffview = ''nvim +"DiffviewOpen $argv"''; };

  programs.zsh.zsh-abbr.abbreviations = {
    nv = "nvim";
    v = "nvim";
    vi = "nvim";
    dv = "diffview";
  };
  programs.zsh.shellAliases = { diffview = ''nvim +"DiffviewOpen $@"''; };

  programs.git.aliases = {
    "dv" = "diffview";
    "diffview" = ''! nvim +"DiffviewOpen $@"'';
  };
}
