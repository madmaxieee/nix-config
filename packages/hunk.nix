{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.10.0";
  release =
    {
      x86_64-linux = {
        asset = "hunkdiff-linux-x64";
        hash = "sha256-ND3Kb1u0B5O+joNCvE4LzJjYpSFnt5QWDFGmuAmYns8=";
      };
      aarch64-linux = {
        asset = "hunkdiff-linux-arm64";
        hash = "sha256-epaG0urTx3nqr2mIClkDLzrxf+gOZE4EDyC0YyEPq8M=";
      };
      x86_64-darwin = {
        asset = "hunkdiff-darwin-x64";
        hash = "sha256-70O4DI3+7ZuZstem8QeiL/qrj9M65nYVflqzqUlpnSY=";
      };
      aarch64-darwin = {
        asset = "hunkdiff-darwin-arm64";
        hash = "sha256-cdiwcZPevnbhlpsHzPeRVsb5WQdunaNlTCKh+XwarUU=";
      };
    }
    .${stdenvNoCC.hostPlatform.system} or (throw ''
      Unsupported system for hunk: ${stdenvNoCC.hostPlatform.system}
    '');
in
stdenvNoCC.mkDerivation rec {
  pname = "hunk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/modem-dev/hunk/releases/download/v${version}/${release.asset}.tar.gz";
    hash = release.hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 "${release.asset}/hunk" "$out/bin/hunk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Review-first terminal diff viewer for agent-authored changesets";
    homepage = "https://github.com/modem-dev/hunk";
    license = licenses.mit;
    mainProgram = "hunk";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
