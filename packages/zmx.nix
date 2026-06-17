{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:

let
  version = "0.6.0";
  release =
    {
      x86_64-linux = {
        os = "linux";
        arch = "x86_64";
        hash = "sha256-fuSxIVDdDXNtJxuhywaUIkTBC4V4QaZjUXKXrGXHIN0=";
      };
      aarch64-darwin = {
        os = "macos";
        arch = "aarch64";
        hash = "sha256-fx5Nln1B3qDfdrx8XdDVeV5+VP1lel8MdPv7LAaZOQ4=";
      };
    }
    .${stdenvNoCC.hostPlatform.system} or (throw ''
      Unsupported system for zmx: ${stdenvNoCC.hostPlatform.system}
    '');
in
stdenvNoCC.mkDerivation {
  pname = "zmx";
  inherit version;

  src = fetchurl {
    url = "https://zmx.sh/a/zmx-${version}-${release.os}-${release.arch}.tar.gz";
    hash = release.hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall
    install -Dm755 zmx "$out/bin/zmx"
    runHook postInstall
  '';

  postInstall = ''
    installShellCompletion --cmd zmx \
      --bash <($out/bin/zmx completions bash) \
      --fish <($out/bin/zmx completions fish) \
      --zsh <($out/bin/zmx completions zsh)
  '';

  meta = with lib; {
    description = "Session persistence for terminal processes";
    homepage = "https://github.com/neurosnap/zmx";
    license = licenses.mit;
    mainProgram = "zmx";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
