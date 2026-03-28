{ pkgs, lib, ... }:
rec {
  home.packages = with pkgs; [
    fnm
    deno
    xh
  ];

  programs.fish.shellAbbrs = {
    pm = lib.mkDefault "pnpm";
    yy = lib.mkDefault "yarn";
    b = lib.mkDefault "bun";
    br = lib.mkDefault "bun run";
  };

  programs.zsh.zsh-abbr.abbreviations = programs.fish.shellAbbrs;

  programs.bun.enable = true;

  xdg.configFile = {
    "fish/conf.d/fnm.fish".text = ''
      status is-interactive || exit 0
      ${pkgs.fnm}/bin/fnm env --use-on-cd --corepack-enabled | source
    '';
  };

  home.activation =
    let
      fnm = "${pkgs.fnm}/bin/fnm";
    in
    {
      fnm_setup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${fnm} install --corepack-enabled --lts
        run ${fnm} default lts-latest
      '';
    };
}
