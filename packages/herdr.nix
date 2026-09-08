{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:

let
  version = "0.9.0";
  release =
    {
      x86_64-linux = {
        os = "linux";
        arch = "x86_64";
        hash = "sha256-T6GgEVjdgEPaktMbJweAsNzBBgMDjZthysTYGrY/tx8=";
      };
      aarch64-darwin = {
        os = "macos";
        arch = "aarch64";
        hash = "sha256-MrU98JhyYoBZx4mmnwKmuOKeFN3yZxFCHzRj9wwa7xc=";
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
    url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-${release.os}-${release.arch}";
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
    homepage = "https://github.com/herdrdev/herdr";
    license = licenses.asl20;
    mainProgram = "herdr";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
