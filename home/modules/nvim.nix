{
  config,
  lib,
  pkgs,
  ...
}:

rec {
  home.activation =
    let
      git = "${pkgs.git}/bin/git";
    in
    {
      clone_nvim_config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d ${config.xdg.configHome}/nvim ]; then
          run ${git} clone git@github.com:madmaxieee/nvim-config.git ${config.xdg.configHome}/nvim
        fi
      '';
    };

  home.packages = with pkgs; [
    ctags
    fd
    ripgrep
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    sideloadInitLua = true;

    withNodeJs = false;
    withPerl = false;
    withPython3 = false;
    withRuby = false;

    extraLuaPackages = ps: with ps; [ luarocks ];
    extraPackages =
      with pkgs;
      [
        # required for nvim-treesitter main branch
        tree-sitter
        gcc

        # for mason
        cargo
        go
        nodejs_24
        python313
        unzip
        xz

        # for formatting, linting, etc.
        nixfmt
        fennel-ls
        fnlfmt

        # for sqlite.lua
        sqlite

        # for snacks image
        imagemagick
        ghostscript
      ]
      ++ (lib.optionals stdenv.isDarwin [
        # for obsidian.nvim, ":Obsidian paste_img"
        pngpaste
      ]);
    extraWrapperArgs = [
      "--set"
      "LIBSQLITE"
      (
        if pkgs.stdenv.isDarwin then
          "${pkgs.sqlite.out}/lib/libsqlite3.dylib"
        else
          "${pkgs.sqlite.out}/lib/libsqlite3.so"
      )
    ];
  };

  programs.fish.shellAbbrs = {
    nv = lib.mkDefault "nvim";
    v = lib.mkDefault "nvim";
    vi = lib.mkDefault "nvim";
    dv = lib.mkDefault "diffview";
  };
  programs.fish.functions = {
    diffview = ''nvim +"DiffviewOpen $argv"'';
  };

  programs.zsh.zsh-abbr.abbreviations = programs.fish.shellAbbrs;
  programs.zsh.shellAliases = {
    diffview = ''nvim +"DiffviewOpen $@"'';
  };

  programs.git.settings.alias = {
    "dv" = "diffview";
    "diffview" = ''! nvim +"DiffviewOpen $@"'';
  };
}
