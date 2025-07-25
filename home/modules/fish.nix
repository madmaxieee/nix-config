{ config, pkgs, ... }:

let
  nix_config_path = "${config.home.homeDirectory}/nix-config";
  linkDotfile = path:
    config.lib.file.mkOutOfStoreSymlink "${nix_config_path}/dotfiles/${path}";
in {
  home.packages = with pkgs; [ fzf ];

  programs.starship.enable = true;

  xdg.configFile = {
    "fish/conf.d/bind.fish".source = linkDotfile "fish/bind.fish";
    "starship.toml".source = linkDotfile "starship/starship.toml";
    "starship_no_git.toml".source = linkDotfile "starship/starship_no_git.toml";
  };

  programs.fish = {
    enable = true;
    shellAbbrs = {
      md = "mkdir -p";
      g = "git";
      n = "nix";
    };
    functions = {
      flush = "string repeat -n(tput lines) \\n";
      clear = "flush";
      fish_greeting = "flush";
      timestamp = "date +%Y-%m-%d_%H-%M-%S";
      __google_starship_config = {
        body = ''
          if path resolve $PWD | grep -q -E '^(/Volumes)?/google'
            set -gx STARSHIP_CONFIG ~/.config/starship_no_git.toml
          else
            set -gx STARSHIP_CONFIG ~/.config/starship.toml
          end
        '';
        onVariable = "PWD";
      };
    };
    interactiveShellInit = ''
      if echo $PATH | grep -q '/nix/store/'
        set -gx IN_NIX_SHELL 1
      end

      if test -d /google && type -q starship
        __google_starship_config
      end

      if type -q brew
        if test -d (brew --prefix)"/share/fish/completions"
          set -p fish_complete_path (brew --prefix)/share/fish/completions
        end
        if test -d (brew --prefix)"/share/fish/vendor_completions.d"
          set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
        end
      end

      function multicd
        echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
      end
      abbr --add dotdot --regex '^\.\.+$' --function multicd

      # if not in tmux, start a new session
      if not set -q TMUX && not set -q IN_NIX_SHELL && type -q tmux
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
          rev = "95e1a08862a2c6149676217e725e351357c0e869";
          hash = "sha256-9plV/fZn1B6z2lUh153yLK/xQdpCOImxHPYGiIJO/lk=";
        };
      }
    ];
  };
}
