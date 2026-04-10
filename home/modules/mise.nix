{ pkgs, lib, ... }:
let
  mise_setup_script = pkgs.writeShellScriptBin "mise_setup" ''
    export PATH="${lib.makeBinPath [ pkgs.curl ]}:$PATH"
    ${lib.getExe pkgs.mise} install
  '';
in
rec {
  programs.mise = {
    enable = true;
    globalConfig = {
      settings = {
        experimental = true;
      };
    };
  };

  programs.mise.enableFishIntegration = false;
  programs.fish.interactiveShellInit = ''
    if ! string match -q "/google/src/cloud/*" "$PWD"
      ${lib.getExe pkgs.mise} activate fish | source
    end
  '';

  programs.fish.shellAbbrs = {
    ms = lib.mkDefault "mise";
  };

  programs.zsh.zsh-abbr.abbreviations = programs.fish.shellAbbrs;

  home.activation = {
    mise_setup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe mise_setup_script}
    '';
  };
}
