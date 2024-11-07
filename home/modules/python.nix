{ pkgs, ... }: {
  home.packages = with pkgs; [ micromamba uv ];
  programs.fish = {
    shellAbbrs = {
      mm = "mamba";
      mma = "mamba activate";
      py = "python3";
    };
    shellAliases = { mamba = "micromamba"; };
  };
  programs.zsh = {
    zsh-abbr.abbreviations = {
      mm = "mamba";
      mma = "mamba activate";
      py = "python3";
    };
    shellAliases = { mamba = "micromamba"; };
  };

  programs.poetry.enable = true;
}
