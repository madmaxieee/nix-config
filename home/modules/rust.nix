{ config, pkgs, lib, ... }: {
  home.packages = with pkgs; [ rustup ];
  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];

  home.activation = let rustup = "${pkgs.rustup}/bin/rustup";
  in {
    rustup_setup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${rustup} default nightly
    '';
  };
}
