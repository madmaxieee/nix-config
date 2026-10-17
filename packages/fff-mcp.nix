{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "v0.11.0";
  release =
    {
      x86_64-linux = {
        target = "x86_64-unknown-linux-musl";
        hash = "sha256-0ehnH0DInERaqhcooh7AS3S+Ll+ZCRSFyuq8yX+ZrOs=";
      };
      aarch64-darwin = {
        target = "aarch64-apple-darwin";
        hash = "sha256-zGBtlBjPp3ZDdtzXsyoz5kWabLmkcYvjZrAk3Kbp/q0=";
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
    url = "https://github.com/dmtrKovalenko/fff/releases/download/${version}/${pname}-${release.target}";
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
    homepage = "https://github.com/dmtrKovalenko/fff";
    license = licenses.mit;
    mainProgram = pname;
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
