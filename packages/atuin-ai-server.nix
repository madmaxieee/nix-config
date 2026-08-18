{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchgit,
  beamPackages,
  gleam,
  git,
  makeWrapper,
  coreutils,
}:

let
  version = "0.1.0-unstable-2026-08-12";
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

  fetchGleamDeps =
    {
      src,
      gitHashes ? { },
    }:
    let
      manifest = builtins.fromTOML (builtins.readFile (src + "/manifest.toml"));
      fetchPkg =
        p:
        if p.source == "hex" then
          beamPackages.fetchHex {
            pkg = p.name;
            inherit (p) version;
            sha256 = p.outer_checksum;
          }
        else if p.source == "git" then
          fetchgit {
            url = p.repo;
            rev = p.commit;
            hash = gitHashes.${p.name} or (throw "Missing gitHashes entry for git dependency ${p.name}");
          }
        else
          throw "Unsupported source ${p.source} for package ${p.name}";

      packagesToml = lib.concatStringsSep "\n" (
        [ "[packages]" ] ++ map (p: "${p.name} = \"${p.version}\"") manifest.packages
      );
    in
    stdenvNoCC.mkDerivation {
      pname = "gleam-deps";
      version = "0.4.0";
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out
        cat <<'EOF' > $out/packages.toml
        ${packagesToml}
        EOF

        ${lib.concatMapStringsSep "\n" (p: ''
          cp -r ${fetchPkg p} $out/${p.name}
          chmod -R u+w $out/${p.name}
        '') manifest.packages}
      '';
    };

  gleamDeps = fetchGleamDeps {
    src = fetchFromGitHub {
      owner = "atuinsh";
      repo = "atuin-ai-core";
      rev = "v0.4.0";
      hash = "sha256-d3YKENwm+C0jGeU/yH36nxbRkb6xcGfNej51ZT8bBCw=";
    };
    gitHashes = {
      dream_http_client = "sha256-O2fWMlRyUXJH5+vF3aauscwiC27IlRJGwSRyjbPe8hQ=";
    };
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
      --prefix PATH : ${lib.makeBinPath [ coreutils ]}
  '';

  meta = with lib; {
    description = "A minimal self-hosted server for the Atuin AI protocol";
    homepage = "https://github.com/atuinsh/atuin-ai-server";
    license = licenses.asl20;
    mainProgram = "atuin_ai_server";
    platforms = platforms.unix;
  };
}
