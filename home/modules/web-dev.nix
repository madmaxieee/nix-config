{ pkgs, lib, ... }: {
  home.packages = with pkgs; [ fnm deno xh ];

  programs.fish.shellAbbrs = {
    pm = lib.mkDefault "pnpm";
    yy = lib.mkDefault "yarn";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    pm = lib.mkDefault "pnpm";
    yy = lib.mkDefault "yarn";
  };

  programs.bun.enable = true;

  xdg.configFile = {
    "fish/conf.d/fnm.fish".text = ''
      status is-interactive || exit 0
      ${pkgs.fnm}/bin/fnm env --use-on-cd --corepack-enabled | source
    '';
  };

  home.activation = let fnm = "${pkgs.fnm}/bin/fnm";
  in {
    fnm_setup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${fnm} install --corepack-enabled --lts
      $DRY_RUN_CMD ${fnm} default lts-latest
    '';
  };
}
