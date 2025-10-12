{ config, pkgs, lib, ... }:

let linkDotfile = config.lib.custom.linkDotfile;
in {
  home.file = {
    ".local/bin/opencode" = {
      # HACK: to set x permission
      target = ".local/bin/.opencode_source";
      text = ''
        #!${pkgs.fish}/bin/fish
        set -x GEMINI_API_KEY (pass gemini/cli 2> /dev/null)
        bunx --bun opencode-ai@latest $argv
      '';
      onChange = let local_bin = "${config.home.homeDirectory}/.local/bin";
      in ''
        rm -f ${local_bin}/opencode
        cp ${local_bin}/.opencode_source ${local_bin}/opencode
        chmod u+x ${local_bin}/opencode
      '';
    };
  };

  xdg.configFile = {
    opencode = {
      source = linkDotfile "opencode";
      recursive = true;
    };
  };

  programs.fish = { shellAbbrs.oc = lib.mkDefault "opencode"; };
  programs.zsh = { zsh-abbr.abbreviations.oc = lib.mkDefault "opencode"; };

  imports = [ ./web-dev.nix ];
}
