{ config, lib, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
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

  # Packages that should be installed to the user profile.
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
    hyperfine
    tealdeer
    tokei
    ffmpeg_7
    typos

    clang
    clang-tools
    cmake
    bear

    micromamba
    uv
    zig
    fnm
    rustup

    kitty
    espanso
    _1password
  ];

  xdg.configFile = {
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
  programs.poetry.enable = true;

  programs.fastfetch.enable = true;

  imports = [
    ./modules/fish.nix
    ./modules/nvim.nix
    ./modules/tmux.nix
    ./modules/window-management.nix
  ];
}
