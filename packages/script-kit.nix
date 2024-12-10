{ lib, pkgs }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  pname = "script-kit";

  version = { aarch64-darwin = "3.10.12"; }.${system} or throwSystem;

  sha256 = {
    aarch64-darwin = "sha256-9EdWyIfQWmPjqBS0g6GpHLd8Hf87DabqGorRSQjDyB8=";
  }.${system} or throwSystem;

  srcs = let base = "https://github.com/script-kit/app/releases/download";
  in {
    aarch64-darwin = {
      url = "${base}/v${version}/Script-Kit-macOS-${version}-arm64.dmg";
      sha256 = sha256;
    };
  };

in pkgs.stdenv.mkDerivation {
  inherit pname version;

  src = pkgs.fetchurl (srcs.${system} or throwSystem);

  meta = with lib; {
    description = "Script Kit. Automate Anything.";
    homepage = "https://scriptkit.com/";
    license = licenses.unfree;
    platforms = [ "aarch64-darwin" ];
  };

  sourceRoot = "Script Kit.app";

  unpackCmd = ''
    echo "File to unpack: $curSrc"
    if ! [[ "$curSrc" =~ \.dmg$ ]]; then return 1; fi
    mnt=$(mktemp -d -t ci-XXXXXXXXXX)

    function finish {
      echo "Detaching $mnt"
      /usr/bin/hdiutil detach $mnt -force
      rm -rf $mnt
    }
    trap finish EXIT

    echo "Attaching $mnt"
    /usr/bin/hdiutil attach -nobrowse -readonly $src -mountpoint $mnt

    echo "What's in the mount dir"?
    ls -la $mnt/

    echo "Copying contents"
    shopt -s extglob
    DEST="$PWD"
    (cd "$mnt"; cp -a !(Applications) "$DEST/")
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications/Script Kit.app"
    cp -R . "$out/Applications/Script Kit.app"
    runHook postInstall
  '';
}
