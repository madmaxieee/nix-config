{
  config,
  pkgs,
  lib,
  ...
}:

let
  flatMerge = sets: lib.mkMerge (lib.flatten sets);
  linkScript = name: {
    ".local/bin/${name}".source = config.lib.custom.linkDotfile "scripts/${name}";
  };
in
{
  home.file = flatMerge [
    (linkScript "fixquote")
    (linkScript "git-foreach")
    (linkScript "mkbash")
    (linkScript "nr")
    (linkScript "ns")
    (linkScript "peek")
    (linkScript "vipe")

    (lib.optionals pkgs.stdenv.isDarwin [
      (linkScript "notify")
      (linkScript "things")
    ])
  ];
}
