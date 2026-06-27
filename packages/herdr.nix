{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.7.1";
  release =
    {
      x86_64-linux = {
        os = "linux";
        arch = "x86_64";
        hash = "sha256-uWWsr/wsIvVLbmxkr3z46Yo/SsJiJjCgWZxnpLnYplQ=";
      };
      aarch64-darwin = {
        os = "macos";
        arch = "aarch64";
        hash = "sha256-FvRlPwSR6h59K0a1sCVC8Y4bguiNqvnikAVy5btjTfg=";
      };
    }
    .${stdenvNoCC.hostPlatform.system} or (throw ''
      Unsupported system for herdr: ${stdenvNoCC.hostPlatform.system}
    '');
in
stdenvNoCC.mkDerivation {
  pname = "herdr";
  inherit version;

  src = fetchurl {
    url = "https://github.com/ogulcancelik/herdr/releases/download/v${version}/herdr-${release.os}-${release.arch}";
    hash = release.hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src "$out/bin/herdr"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://github.com/ogulcancelik/herdr";
    license = licenses.agpl3Plus;
    mainProgram = "herdr";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
