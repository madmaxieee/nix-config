{ config, pkgs, lib, sources, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  home.packages = with pkgs; [ fzf ];
  home.shell.enableFishIntegration = true;
  programs.starship.enable = true;

  xdg.configFile = {
    "fish/conf.d/bind.fish".source = linkDotfile "fish/bind.fish";
    "starship.toml".source = linkDotfile "starship/starship.toml";
    "starship_no_git.toml".source = linkDotfile "starship/starship_no_git.toml";
  };

  programs.fish = {
    enable = true;
    shellAbbrs = { md = lib.mkDefault "mkdir -p"; };
    functions = {
      flush = "string repeat -n(tput lines) \\n";
      clear = "flush";
      fish_greeting = "flush";
      timestamp = "date +%Y-%m-%d_%H-%M-%S";
      cdn = ''
        cd (find . -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\n" | sort -n | tail -n1 | cut -d' ' -f2-)'';
      __starship_no_git = {
        body = ''
          if pwd | grep -q '^/google'
            set -gx STARSHIP_CONFIG ~/.config/starship_no_git.toml
          else if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && not timeout 0.5s git status >/dev/null 2>&1
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
        __starship_no_git
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
        src = sources.autopair-fish;
      }
      {
        name = "fzf.fish";
        src = sources.fzf-fish;
      }
      {
        name = "vipe.fish";
        src = sources.vipe-fish;
      }
    ];
  };

  programs.tmux.shell = "${pkgs.fish}/bin/fish";
}
