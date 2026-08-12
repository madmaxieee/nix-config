{
  config,
  pkgs,
  lib,
  ...
}:

let
  herdr = pkgs.callPackage ../../packages/herdr.nix { };
  linkDotfile = config.lib.custom.linkDotfile;
in
rec {
  home.packages = [
    herdr

    # personal plugin dependencies
    pkgs.fzf
    pkgs.python313
  ];

  programs.fish = {
    functions = {
      alert = lib.mkDefault ''
        if test (count $argv) -eq 0
            echo "Usage: alert <command...>"
            return 1
        end

        set -l cmd_str (string join " " $argv)
        $argv
        set -l exit_code $status

        set -l title "Task Succeeded"
        set -l sound "done"
        if test $exit_code -ne 0
            set title "Task Failed"
            set sound "request"
            set cmd_str "$cmd_str (exit: $exit_code)"
        end

        if set -q HERDR_PANE_ID
            herdr notification show "$title" --body "$cmd_str" --sound "$sound" >/dev/null 2>&1
        else if test (uname) = "Darwin"
            osascript -e "display notification \"$cmd_str\" with title \"$title\"" >/dev/null 2>&1
        else
            printf '\a'
        end

        return $exit_code
      '';
      herdr-remote = lib.mkDefault ''
        if test (count $argv) -ne 1
            echo "Usage: herdr-remote <remote-host>"
            return
        end
        set -f ssh_host $argv[1]

        if type -q autogcert
            autogcert $ssh_host
        end

        caffeinate -i herdr --remote-keybindings server --remote $ssh_host
      '';
    };
    shellAbbrs = {
      h = lib.mkDefault "herdr";
      hr = lib.mkDefault "herdr-remote";
    };
  };

  programs.zsh = {
    shellAliases = programs.fish.functions;
    zsh-abbr.abbreviations = programs.fish.shellAbbrs;
  };

  xdg.configFile = {
    "herdr/config.toml".source = linkDotfile "herdr/config.toml";
  };

  home.activation = {
    herdr_plugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${herdr}/bin/herdr integration install opencode
      run ${herdr}/bin/herdr plugin link ~/nix-config/dotfiles/herdr/plugins/herdr-sesh-workspaces
      run ${herdr}/bin/herdr plugin link ~/nix-config/dotfiles/herdr/plugins/mru-workspace
    '';
  };

  imports = [
    # for creating workspaces from zoxide query
    ./zoxide.nix
  ];
}
