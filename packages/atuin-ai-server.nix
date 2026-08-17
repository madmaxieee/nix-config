{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  beamPackages,
  gleam,
  git,
  cacert,
  makeWrapper,
  pass,
  gnupg,
  coreutils,
}:

let
  version = "0.1.0-unstable-2026-03-24";
  src = fetchFromGitHub {
    owner = "atuinsh";
    repo = "atuin-ai-server";
    rev = "4d582bc5ceea5b5edfdcf3abb49dc850400cda7c";
    hash = "sha256-+Iqqd12yUHOSm29uHUeWs2Z9fnutH9fOoTLb9EdvPMY=";
  };

  mixFodDeps = beamPackages.fetchMixDeps {
    pname = "atuin-ai-server-deps";
    inherit version src;
    hash = "sha256-KV0Ea5iPFEZbOzyoPOuk/4dG8NylBg1EZLij5mRCtA8=";
  };

  gleamDeps = stdenvNoCC.mkDerivation {
    pname = "atuin-ai-core-gleam-deps";
    version = "0.4.0";
    src = fetchFromGitHub {
      owner = "atuinsh";
      repo = "atuin-ai-core";
      rev = "v0.4.0";
      hash = "sha256-d3YKENwm+C0jGeU/yH36nxbRkb6xcGfNej51ZT8bBCw=";
    };

    nativeBuildInputs = [
      gleam
      git
      cacert
    ];

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-fs/3F4pcKbU/HLHQ2QUlbRIcOo9eF7poDar43qlGfjA=";

    buildPhase = ''
      export HOME="$TMPDIR"
      export SSL_CERT_FILE="$NIX_SSL_CERT_FILE"
      export GIT_SSL_CAINFO="$NIX_SSL_CERT_FILE"
      gleam deps download
    '';

    installPhase = ''
      mkdir -p $out
      find build/packages -name ".git" -exec rm -rf {} + || true
      cp -r build/packages/* $out/
    '';
  };
in
beamPackages.mixRelease {
  pname = "atuin-ai-server";
  inherit version src mixFodDeps;
  removeCookie = false;

  nativeBuildInputs = [
    gleam
    git
    makeWrapper
  ];

  postConfigure = ''
    if [ -d "deps/atuin_ai_core" ]; then
      mkdir -p deps/atuin_ai_core/build/packages
      cp -r ${gleamDeps}/* deps/atuin_ai_core/build/packages/
      chmod -R u+w deps/atuin_ai_core/build/packages
    fi
  '';

  postFixup = ''
    wrapProgram $out/bin/atuin_ai_server \
      --prefix PATH : ${
        lib.makeBinPath [
          pass
          gnupg
          coreutils
        ]
      }
  '';

  meta = with lib; {
    description = "A minimal self-hosted server for the Atuin AI protocol";
    homepage = "https://github.com/atuinsh/atuin-ai-server";
    license = licenses.asl20;
    mainProgram = "atuin_ai_server";
    platforms = platforms.unix;
  };
}
