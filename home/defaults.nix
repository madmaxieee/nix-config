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
        ${git} clone https://github.com/madmaxieee/nix-config.git ${nix_config_path}
      fi
    '';
  };

  # Packages that should be installed to the user profile.
  home.packages = [
    pkgs.fzf
    pkgs.jq
    pkgs.mods
    pkgs.gh
    pkgs.lazygit
    pkgs.pass
    pkgs.gnupg
    pkgs.git-lfs

    pkgs.ripgrep
    pkgs.fd
    pkgs.eza
    pkgs.bat
    pkgs.difftastic
    pkgs.wget

    pkgs.rm-improved
    pkgs.dust
    pkgs.delta
    pkgs.mprocs
    pkgs.hyperfine
    pkgs.tealdeer
    pkgs.tokei
    pkgs.typos

    pkgs.llvm_17
    pkgs.jdk21_headless
    pkgs.micromamba
    pkgs.uv
    pkgs.go
    pkgs.zig
    pkgs.fnm
    pkgs.bun
    pkgs.rustup

    pkgs.kitty
    pkgs.espanso
    pkgs._1password
  ];

  home.file = {
    ".gitconfig".source = linkDotfile "git/gitconfig";
    ".gitignore".source = linkDotfile "git/gitignore";
    ".hammerspoon" = {
      source = linkDotfile "hammerspoon";
      recursive = true;
    };
    ".simplebarrc".source = linkDotfile "simple-bar/simplebarrc";
  };

  xdg.configFile = {
    "starship.toml".source = linkDotfile "starship/starship.toml";
    "fish/conf.d/bind.fish".source = linkDotfile "fish/bind.fish";
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
    "gh" = {
      source = linkDotfile "gh";
      recursive = false;
    };
    "ubersicht/widgets/simple-bar".source = builtins.fetchGit {
      url = "git@github.com:madmaxieee/simple-bar.git";
      rev = "1240a1d5e0aa546a77ae680277e87aa5b39d46b1";
    };
  };

  programs.poetry.enable = true;

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
      t = "${config.xdg.configHome}/tmux/scripts/sesh.sh";
    };
    functions = {
      flush = "string repeat -n(tput lines) \\n";
      clear = "flush";
      fish_greeting = "flush";
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

      # if not in tmux, start a new session
      if [ -z "$TMUX" ]
          tmux new-session -A -s main >/dev/null 2>&1
      end

      # >>> mamba initialize >>>
      # !! Contents within this block are managed by 'mamba init' !!
      set -gx MAMBA_EXE "/run/current-system/sw/bin/micromamba"
      set -gx MAMBA_ROOT_PREFIX "/Users/madmax/micromamba"
      $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
      # <<< mamba initialize <<<

      if test -d (brew --prefix)"/share/fish/completions"
          set -p fish_complete_path (brew --prefix)/share/fish/completions
      end

      if test -d (brew --prefix)"/share/fish/vendor_completions.d"
          set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
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

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "linode" = {
        hostname = "linode.madmaxieee.dev";
        user = "madmax";
      };
      "soft" = {
        hostname = "soft.madmaxieee.dev";
        port = 23231;
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      "cthulhu" = {
        hostname = "cthulhu.ee.ntu.edu.tw";
        user = "madmax";
      };
      "athena" = {
        hostname = "athena.ee.ntu.edu.tw";
        user = "madmax";
      };
      "valkyrie" = {
        hostname = "valkyrie.ee.ntu.edu.tw";
        user = "madmax";
      };
      "zeus" = {
        hostname = "zeus.ee.ntu.edu.tw";
        user = "madmax";
      };
    };
  };

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

  imports = [ ../modules/nvim.nix ../modules/tmux.nix ];
}
