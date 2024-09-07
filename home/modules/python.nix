{ pkgs, ... }: {
  home.packages = with pkgs; [ micromamba uv ];
  programs.fish = {
    shellAbbrs = {
      mm = "mamba";
      mma = "mamba activate";
    };
    shellAliases = { mamba = "micromamba"; };
  };

  programs.poetry.enable = true;
}
