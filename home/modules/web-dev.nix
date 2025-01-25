{ pkgs, ... }: {
  home.packages = with pkgs; [ fnm deno ];

  programs.fish.shellAbbrs = {
    b = "bun";
    pm = "pnpm";
    yy = "yarn";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    b = "bun";
    pm = "pnpm";
    yy = "yarn";
  };

  programs.bun.enable = true;

  xdg.configFile = {
    "fish/conf.d/fnm.fish".text = ''
      status is-interactive || exit 0
      fnm env --use-on-cd | source
    '';
  };
}
