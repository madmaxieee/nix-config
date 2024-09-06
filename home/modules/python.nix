{ pkgs, ... }: {
  home.packages = with pkgs; [ micromamba uv ];
  programs.fish = {
    mm = "mamba";
    shellAbbrs = { mma = "mamba activate"; };
    shellAliases = { mamba = "micromamba"; };
  };

  programs.poetry.enable = true;
}
