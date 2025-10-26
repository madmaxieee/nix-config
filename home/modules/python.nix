{ config, pkgs, lib, ... }: rec {
  home.packages = with pkgs; [
    micromamba
    uv
    python312
    python312Packages.ipython
  ];

  programs.fish = {
    shellAbbrs = {
      mb = lib.mkDefault "mamba";
      mba = lib.mkDefault "mamba activate";
      py = lib.mkDefault "python3";
      ipy = lib.mkDefault "ipython";
    };
    functions = {
      __mamba_init = ''
        # >>> mamba initialize >>>
        # !! Contents within this block are managed by 'mamba init' !!
        set -gx MAMBA_EXE "${pkgs.micromamba}/bin/micromamba"
        set -gx MAMBA_ROOT_PREFIX "${config.home.homeDirectory}/micromamba"
        $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
        # <<< mamba initialize <<<
      '';
      mamba = ''
        if not set -q MAMBA_EXE
          __mamba_init
        end
        micromamba $argv
      '';
    };
  };

  programs.zsh = { zsh-abbr.abbreviations = programs.fish.shellAbbrs; };
}
