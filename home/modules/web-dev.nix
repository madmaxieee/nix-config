{ pkgs, ... }: {
  home.packages = with pkgs; [ fnm deno ];

  programs.fish.shellAbbrs = {
    d = "docker";
    dco = "docker compose";
    ya = "yarn";
    pm = "pnpm";
  };

  programs.zsh.zsh-abbr.abbreviations = {
    d = "docker";
    dco = "docker compose";
    ya = "yarn";
    pm = "pnpm";
  };

  programs.bun.enable = true;
}
