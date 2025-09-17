{ config, pkgs, lib, ... }: {
  home.packages = with pkgs; [ micromamba uv python312 ];
  programs.fish = {
    shellAbbrs = {
      mb = lib.mkDefault "mamba";
      mba = lib.mkDefault "mamba activate";
      py = lib.mkDefault "python3";
    };
    shellAliases = { mamba = "micromamba"; };
  };
  programs.zsh = {
    zsh-abbr.abbreviations = {
      mb = lib.mkDefault "mamba";
      mba = lib.mkDefault "mamba activate";
      py = lib.mkDefault "python3";
    };
    shellAliases = { mamba = "micromamba"; };
  };

  programs.poetry.enable = true;

  xdg.configFile = {
    "fish/conf.d/mamba.fish".text = ''
      status is-interactive || exit 0
      # >>> mamba initialize >>>
      # !! Contents within this block are managed by 'mamba init' !!
      set -gx MAMBA_EXE "${pkgs.micromamba}/bin/micromamba"
      set -gx MAMBA_ROOT_PREFIX "${config.home.homeDirectory}/micromamba"
      $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
      # <<< mamba initialize <<<
    '';
  };
}
