{ config, lib, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.activation = let git = "${pkgs.git}/bin/git";
  in {
    clone_dotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${nix_config_path} ]; then
        $DRY_RUN_CMD ${git} clone https://github.com/madmaxieee/nix-config.git ${nix_config_path}
      fi
    '';
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    sd
    difftastic
    wget
    rm-improved
    dust

    parallel
    entr
    fzf
    jq
    mods
    lazygit
    pass
    gnupg

    mprocs
    tealdeer
    tokei
    ffmpeg_7
    typos

    clang
    clang-tools
    cmake
    bear

    zig
    fnm
    rustup

    kitty
    espanso
    _1password
  ];

  xdg.configFile = {
    "fish/completions/brew.fish".source = builtins.fetchurl {
      url =
        "https://raw.githubusercontent.com/Homebrew/brew/4.3.15/completions/fish/brew.fish";
      sha256 =
        "e682ad20844b33f5150f3d9881b2eb8d20dcbdc060966aa75040180a90b04385";
    };
    "kitty" = {
      source = linkDotfile "kitty";
      recursive = false;
    };
    "espanso" = {
      source = linkDotfile "espanso";
      recursive = false;
    };
  };

  home.sessionVariables.PAGER = "bat -p";

  programs.zoxide.enable = true;
  home.sessionVariables = {
    "_ZO_DATA_DIR" = "${config.home.homeDirectory}/.local/share";
    "_ZO_RESOLVE_SYMLINKS" = "1";
    "_ZO_EXCLUDE_DIRS" = "/nix/store/*";
  };

  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
  };

  programs.bun.enable = true;
  programs.java.enable = true;
  programs.gradle.enable = true;
  programs.go.enable = true;

  programs.fastfetch.enable = true;

  programs.fish.shellAbbrs = {
    copy = "pbcopy";
    paste = "pbpaste";
  };

  imports = [
    ./modules/fish.nix
    ./modules/nvim.nix
    ./modules/tmux.nix
    ./modules/window-management.nix

    ./modules/python.nix
  ];
}
