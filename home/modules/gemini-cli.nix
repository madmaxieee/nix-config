{ ... }:
{
  programs.fish.functions.gemini = {
    body = ''
      if test -d /google/bin
        /google/bin/releases/gemini-cli/tools/gemini --gfg $argv
      else
        set -x GEMINI_API_KEY (pass gemini/cli 2> /dev/null)
        pnpx https://github.com/google-gemini/gemini-cli $argv
      end
    '';
  };

  imports = [
    ./password-store.nix
    ./web-dev.nix
  ];
}
