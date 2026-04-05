{ pkgs, lib, ... }:
rec {
  programs.mise = {
    enable = true;
    globalConfig = {
      settings = {
        experimental = true;
      };
    };
  };

  programs.fish.shellAbbrs = {
    ms = lib.mkDefault "mise";
  };

  programs.zsh.zsh-abbr.abbreviations = programs.fish.shellAbbrs;

  home.activation = {
    mise_setup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe pkgs.mise} install
    '';
  };
}
