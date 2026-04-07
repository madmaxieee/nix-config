{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "v0.5.2";
  release =
    {
      x86_64-linux = {
        target = "x86_64-unknown-linux-musl";
        hash = "sha256-o7AoV75bm6mR4bn7nmvbA7dCEtpEe2IbuwKEN0g8NJo=";
      };
      aarch64-darwin = {
        target = "aarch64-apple-darwin";
        hash = "sha256-RrK7HWAGrZxgNoBeG1MdY2cYqBprAQ0NwVzNKEbissk=";
      };
    }
    .${stdenvNoCC.hostPlatform.system} or (throw ''
      Unsupported system for fff-mcp: ${stdenvNoCC.hostPlatform.system}
    '');
in
stdenvNoCC.mkDerivation rec {
  pname = "fff-mcp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/dmtrKovalenko/fff.nvim/releases/download/${version}/${pname}-${release.target}";
    hash = release.hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/${pname}"
    runHook postInstall
  '';

  meta = with lib; {
    description = "FFF MCP server";
    homepage = "https://github.com/dmtrKovalenko/fff.nvim";
    license = licenses.mit;
    mainProgram = pname;
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
