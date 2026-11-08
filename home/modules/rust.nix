{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];

  home.file = {
    ".cargo/config.toml".text = ''
      [build]
      rustc-wrapper = "${lib.getExe pkgs.sccache}"

      [net]
      git-fetch-with-cli = true
    '';
  };

  programs.bacon.enable = true;

  # rustup, not mise, owns the toolchains: mise pins "nightly" to a dated
  # toolchain that only takes effect through RUSTUP_TOOLCHAIN, which would
  # override rust-toolchain.toml. rustup alone honours rust-toolchain.toml
  # and falls back to its default, the nightly channel kept current here.
  # rustup lives in ~/.cargo/bin, not the nix store, so it can self-update.
  home.activation.rustup_default =
    let
      rustup = "${config.home.homeDirectory}/.cargo/bin/rustup";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x "${rustup}" ]; then
        run ${lib.getExe pkgs.curl} --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
          | run sh -s -- -y --no-modify-path --default-toolchain nightly
      fi
      run "${rustup}" default nightly
      run "${rustup}" update
    '';
}
