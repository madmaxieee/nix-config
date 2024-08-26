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

  home.file = {
    ".simplebarrc".source = linkDotfile "simple-bar/simplebarrc";
    ".hammerspoon" = {
      source = linkDotfile "hammerspoon";
      recursive = false;
    };
    # hack to make hammerspoon find nix binaries
    "nix-config/dotfiles/hammerspoon/nix_path.lua".text = ''
      NIX_PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
    '';
  };

  xdg.configFile = {
    "starship.toml".source = linkDotfile "starship/starship.toml";
    "fish/conf.d/bind.fish".source = linkDotfile "fish/bind.fish";
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
    "skhd" = {
      source = linkDotfile "skhd";
      recursive = false;
    };
    "yabai" = {
      source = linkDotfile "yabai";
      recursive = false;
    };
    "espanso" = {
      source = linkDotfile "espanso";
      recursive = false;
    };
    "ubersicht/widgets/simple-bar".source = builtins.fetchGit {
      url = "git@github.com:madmaxieee/simple-bar.git";
      rev = "1240a1d5e0aa546a77ae680277e87aa5b39d46b1";
    };
  };

  programs.fish = {
    enable = true;
    shellAbbrs = {
      md = "mkdir -p";
      d = "docker";
      dco = "docker compose";
      g = "git";
      lg = "lazygit";
      y = "yarn";
      pm = "pnpm";
      py = "python3";
      v = "nvim";
      vi = "nvim";
      copy = "pbcopy";
      paste = "pbpaste";
      mm = "mamba";
      mma = "mamba activate";
      rm = "rip";
      rmm = "rm -rf";
      n = "npm";
      ta = "tmux attach";
      gr = "gradle";
      grr = "gradle -q --console plain run";
    };
    shellAliases = {
      cat = "bat -p";
      l = "eza";
      ls = "eza --icons";
      la = "eza --icons --all";
      ll = "eza --icons --long --group";
      lla = "eza --icons --long --group --all";
      tree = "eza -T -a -I .git";
      mamba = "micromamba";
      rsync = "rsync --progress --archive";
      dequarantine = "xattr -d com.apple.quarantine";
      icat = "kitten icat";
    };
    functions = {
      flush = "string repeat -n(tput lines) \\n";
      clear = "flush";
      fish_greeting = "flush";
      modsq = ''
        set -x OPENAI_API_KEY (pass openai/mods)
        mods $argv
      '';
    };
    interactiveShellInit = ''
      fish_vi_key_bindings
      set fish_cursor_default block
      set fish_cursor_insert line
      set fish_cursor_replace_one underscore
      set fish_cursor_visual block

      if type -q fnm
        fnm env --use-on-cd | source
      end

      if [ $TERM = xterm-kitty ]
          alias ssh='TERM=xterm-256color /usr/bin/ssh'
      end

      # >>> mamba initialize >>>
      # !! Contents within this block are managed by 'mamba init' !!
      set -gx MAMBA_EXE "${config.home.profileDirectory}/bin/micromamba"
      set -gx MAMBA_ROOT_PREFIX "${config.home.homeDirectory}/micromamba"
      $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
      # <<< mamba initialize <<<

      if test -d (brew --prefix)"/share/fish/completions"
          set -p fish_complete_path (brew --prefix)/share/fish/completions
      end

      if test -d (brew --prefix)"/share/fish/vendor_completions.d"
          set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
      end

      # if not in tmux, start a new session
      if [ -z "$TMUX" ]
          tmux new-session -A -s main >/dev/null 2>&1
      end
    '';
    plugins = [
      {
        name = "autopair.fish";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "autopair.fish";
          rev = "1.0.4";
          sha256 = "sha256-s1o188TlwpUQEN3X5MxUlD/2CFCpEkWu83U9O+wg3VU=";
        };
      }
      {
        name = "fzf.fish";
        src = pkgs.fetchFromGitHub {
          owner = "patrickf1";
          repo = "fzf.fish";
          rev = "v10.3";
          sha256 = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
        };
      }
      {
        name = "vipe.fish";
        src = pkgs.fetchFromGitHub {
          owner = "madmaxieee";
          repo = "vipe.fish";
          rev = "de948ed4cac4fb9b5d4974874f7d0d6f8e9652b5";
          sha256 = "sha256-JvlCRZECUXMk9D5jPWvJkzwFq1N5G3q+KTwUXlSJSTw=";
        };
      }
    ];
  };

  home.sessionVariables.PAGER = "bat -p";

  programs.starship.enable = true;

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

  imports = [ ../modules/nvim.nix ../modules/tmux.nix ../modules/git.nix ];
}
