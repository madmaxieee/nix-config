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
    # keep-sorted start
    (linkScript "clip")
    (linkScript "fixquote")
    (linkScript "git-foreach")
    (linkScript "kseq")
    (linkScript "mkbash")
    (linkScript "nr")
    (linkScript "ns")
    (linkScript "peek")
    (linkScript "vipe")
    # keep-sorted end

    (lib.optionals pkgs.stdenv.isDarwin [
      (linkScript "notify")
      (linkScript "things")
    ])
  ];
}
