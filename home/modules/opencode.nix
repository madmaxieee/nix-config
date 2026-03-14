{
  config,
  pkgs,
  lib,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.file = {
    ".local/bin/opencode" = {
      executable = true;
      text = ''
        #!${pkgs.fish}/bin/fish
        if not set -q GEMINI_API_KEY
          set -x GEMINI_API_KEY (pass gemini/cli 2> /dev/null)
        end
        pnpx opencode-ai@latest $argv
      '';
    };
  };

  xdg.configFile = {
    "opencode/opencode.jsonc".source = linkDotfile "opencode/opencode.jsonc";
    "opencode/tui.jsonc".source = linkDotfile "opencode/tui.jsonc";
  };

  programs.fish = {
    shellAbbrs.oc = lib.mkDefault "opencode";
  };
  programs.zsh = {
    zsh-abbr.abbreviations.oc = lib.mkDefault "opencode";
  };

  imports = [
    ./password-store.nix
    ./web-dev.nix
  ];
}
