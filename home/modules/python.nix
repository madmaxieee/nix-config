{ config, pkgs, ... }: {
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

  xdg.configFile = {
    "fish/conf.d/mamba.fish".text = ''
      status is-interactive || exit 0
      # >>> mamba initialize >>>
      # !! Contents within this block are managed by 'mamba init' !!
      set -gx MAMBA_EXE "${config.home.profileDirectory}/bin/micromamba"
      set -gx MAMBA_ROOT_PREFIX "${config.home.homeDirectory}/micromamba"
      $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
      # <<< mamba initialize <<<
    '';
  };
}
