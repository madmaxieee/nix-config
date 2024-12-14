{ lib, pkgs }:

let version = "3.10.12";
in pkgs.stdenv.mkDerivation {
  inherit version;
  name = "script-kit";
  pname = "script-kit";

  src = pkgs.fetchurl {
    url =
      "https://github.com/script-kit/app/releases/download/v${version}/Script-Kit-macOS-${version}-arm64.dmg";
    sha256 = "sha256-9EdWyIfQWmPjqBS0g6GpHLd8Hf87DabqGorRSQjDyB8=";
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

  meta = with lib; {
    description = "Script Kit. Automate Anything.";
    homepage = "https://scriptkit.com/";
    license = licenses.unfree;
    platforms = [ "aarch64-darwin" ];
  };
}
