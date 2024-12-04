{ pkgs, ... }: {
  home.packages = with pkgs; [ micromamba uv ];
  programs.fish = {
    shellAbbrs = {
      mb = "mamba";
      mba = "mamba activate";
      py = "python3";
    };
    shellAliases = { mamba = "micromamba"; };
  };
  programs.zsh = {
    zsh-abbr.abbreviations = {
      mb = "mamba";
      mba = "mamba activate";
      py = "python3";
    };
    shellAliases = { mamba = "micromamba"; };
  };

  programs.poetry.enable = true;
}
