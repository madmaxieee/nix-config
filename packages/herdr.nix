{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:

let
  version = "0.7.5";
  release =
    {
      x86_64-linux = {
        os = "linux";
        arch = "x86_64";
        hash = "sha256-PcgyiAc+TC08Z5ow576XvMqRQcb9F9u7khkULpXFklM=";
      };
      aarch64-darwin = {
        os = "macos";
        arch = "aarch64";
        hash = "sha256-NzUFRrABJVWUO5Lq+WJmXeTiZDlbrrRCJ7gBXo/1sNY=";
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

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd herdr \
      --bash <($out/bin/herdr completion bash) \
      --fish <($out/bin/herdr completion fish) \
      --zsh <($out/bin/herdr completion zsh)
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
