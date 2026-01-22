{ ... }: {
  programs.fish.functions.gemini = {
    body = ''
      set -x GEMINI_API_KEY (pass gemini/cli 2> /dev/null)
      pnpx https://github.com/google-gemini/gemini-cli $argv
    '';
  };

  imports = [ ./password-store.nix ./web-dev.nix ];
}
