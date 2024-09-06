{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  programs.starship.enable = true;
  programs.tmux.enable = true;

  home.packages = with pkgs; [
    eza
    bat
    rm-improved

    fzf
    lazygit

    micromamba
    fnm
  ];

  xdg.configFile = {
    "fish/conf.d/bind.fish".source = linkDotfile "fish/bind.fish";
    "starship.toml".source = linkDotfile "starship/starship.toml";
    "starship_google.toml".source = linkDotfile "starship/starship_google.toml";
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
      __google_starship_config = {
        body = ''
          if path resolve $PWD | grep -q '^/Volumes/google/src'
            set -gx STARSHIP_CONFIG ~/.config/starship_google.toml
          else
            set -gx STARSHIP_CONFIG ~/.config/starship.toml
          end
        '';
        onVariable = "PWD";
      };
    };
    interactiveShellInit = ''
      if test -d /Volumes/google
        __google_starship_config
      end

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

      if type -q brew
        if test -d (brew --prefix)"/share/fish/completions"
            set -p fish_complete_path (brew --prefix)/share/fish/completions
        end
        if test -d (brew --prefix)"/share/fish/vendor_completions.d"
            set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
        end
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
}
