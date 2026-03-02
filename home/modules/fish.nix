{
  config,
  pkgs,
  lib,
  sources,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.packages = with pkgs; [ fzf ];
  home.shell.enableFishIntegration = true;

  xdg.configFile = {
    "fish/conf.d/bind.fish".source = linkDotfile "fish/bind.fish";
  };

  programs.fish = {
    enable = true;
    shellAbbrs = {
      md = lib.mkDefault "mkdir -p";
    };
    functions = {
      flush = "string repeat -n(tput lines) \\n";
      clear = "flush";
      fish_greeting = "flush";
      timestamp = "date +%Y-%m-%d_%H-%M-%S";
      cdn = ''
        set -f target_dir (find . -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\n" |
          grep -E -v '\.(git|jj)' |
          sort -n |
          tail -n1 |
          cut -d' ' -f2-)
        if test -n "$target_dir"
          cd $target_dir
        end
      '';
      __dotdot = ''
        echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
      '';
    };
    interactiveShellInit = ''
      if echo $PATH | grep -q '/nix/store/'
        set -gx IN_NIX_SHELL 1
      end

      if type -q brew
        set -l brew_prefix (brew --prefix)
        if test -d "$brew_prefix/share/fish/completions"
          set -p fish_complete_path "$brew_prefix/share/fish/completions"
        end
        if test -d "$brew_prefix/share/fish/vendor_completions.d"
          set -p fish_complete_path "$brew_prefix/share/fish/vendor_completions.d"
        end
      end

      abbr --add dotdot --regex '^\.\.+$' --function __dotdot

      # if not in tmux, start a new session
      if not set -q TMUX && not set -q ZELLIJ && not set -q IN_NIX_SHELL && type -q tmux
        tmux new-session -A -s main >/dev/null 2>&1
      end
    '';

    # unmanaged fish config files con be placed in ~/.config/fish/after/
    shellInitLast = ''
      begin
        set -l after_dir "$__fish_config_dir"/after
        if test -d $after_dir
            for f in (find -L "$after_dir" -type f -name '*.fish' | sort)
                source $f
            end
        end
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
