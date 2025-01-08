{ pkgs, ... }: {
  home.packages = with pkgs; [ fnm deno ];

  programs.fish.shellAbbrs = {
    d = "docker";
    dco = "docker compose";
    yy = "yarn";
    pm = "pnpm";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    d = "docker";
    dco = "docker compose";
    yy = "yarn";
    pm = "pnpm";
  };

  programs.bun.enable = true;

  xdg.configFile = {
    "fish/conf.d/fnm.fish".text = ''
      status is-interactive || exit 0
      fnm env --use-on-cd | source
    '';
  };
}
