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
  home.packages = [ herdr ];

  programs.fish = {
    functions = {
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
    "fish/completions/herdr.fish".source = linkDotfile "fish/completions/herdr.fish";
    "herdr/config.toml".source = linkDotfile "herdr/config.toml";
  };

  home.activation = {
    herdr_plugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${herdr}/bin/herdr integration install opencode
      run ${herdr}/bin/herdr plugin link ~/nix-config/dotfiles/herdr/plugins/herdr-sesh-workspaces
      run ${herdr}/bin/herdr plugin link ~/nix-config/dotfiles/herdr/plugins/mru-workspace
    '';
  };
}
