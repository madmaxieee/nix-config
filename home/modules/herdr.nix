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

  programs.fish.shellAbbrs = {
    h = lib.mkDefault "herdr";
  };

  programs.zsh = {
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
