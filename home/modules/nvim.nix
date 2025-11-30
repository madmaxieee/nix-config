{ config, lib, pkgs, ... }:

rec {
  home.activation = let git = "${pkgs.git}/bin/git";
  in {
    clone_nvim_config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${config.xdg.configHome}/nvim ]; then
        run ${git} clone git@github.com:madmaxieee/nvim-config.git ${config.xdg.configHome}/nvim
      fi
    '';
  };

  home.packages = with pkgs; [ ripgrep fd lazygit ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraLuaPackages = ps: with ps; [ luarocks ];
    extraPackages = with pkgs;
      [
        # required for nvim-treesitter main branch
        tree-sitter

        # for mason
        cargo
        go
        nodejs_20
        python312
        unzip
        xz

        # for formatting, linting, etc.
        nixfmt-classic
        fennel-ls

        # for sqlite.lua
        sqlite

        # for snacks image
        imagemagick
        ghostscript
      ] ++ (lib.optionals stdenv.isDarwin [
        # for obsidian.nvim, ":Obsidian paste_img"
        pngpaste
      ]);
    extraWrapperArgs = [
      "--set"
      "LIBSQLITE"
      (if pkgs.stdenv.isDarwin then
        "${pkgs.sqlite.out}/lib/libsqlite3.dylib"
      else
        "${pkgs.sqlite.out}/lib/libsqlite3.so")

    ];
  };

  programs.fish.shellAbbrs = {
    nv = lib.mkDefault "nvim";
    v = lib.mkDefault "nvim";
    vi = lib.mkDefault "nvim";
    dv = lib.mkDefault "diffview";
  };
  programs.fish.functions = { diffview = ''nvim +"DiffviewOpen $argv"''; };

  programs.zsh.zsh-abbr.abbreviations = programs.fish.shellAbbrs;
  programs.zsh.shellAliases = { diffview = ''nvim +"DiffviewOpen $@"''; };

  programs.git.settings.alias = {
    "dv" = "diffview";
    "diffview" = ''! nvim +"DiffviewOpen $@"'';
  };
}
