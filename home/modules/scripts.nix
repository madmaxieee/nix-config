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
  # Pin only these commands so builds launched by git-foreach retain the user's PATH.
  gitForeach = pkgs.substitute {
    src = ../../dotfiles/scripts/git-foreach;
    isExecutable = true;
    substitutions = [
      "--replace-fail"
      "#!/usr/bin/env bash"
      "#!${pkgs.bash}/bin/bash"
      "--replace-fail"
      "realpath "
      "${pkgs.coreutils}/bin/realpath "
      "--replace-fail"
      "dirname -z"
      "${pkgs.coreutils}/bin/dirname -z"
      "--replace-fail"
      "sort -z"
      "${pkgs.coreutils}/bin/sort -z"
    ];
  };
in
{
  home.file = flatMerge [
    # keep-sorted start
    (linkScript "clip")
    (linkScript "fixquote")
    (linkScript "kseq")
    (linkScript "mkbash")
    (linkScript "nr")
    (linkScript "ns")
    (linkScript "peek")
    (linkScript "vipe")
    # keep-sorted end

    { ".local/bin/git-foreach".source = gitForeach; }

    (lib.optionals pkgs.stdenv.isDarwin [
      (linkScript "notify")
      (linkScript "things")
    ])
  ];
}
