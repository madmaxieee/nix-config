{ config, pkgs, ... }:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  programs.starship.enable = true;

  home.packages = with pkgs; [ jj-starship ];

  xdg.configFile = {
    "starship.toml".source = linkDotfile "starship/starship.toml";
    "starship_no_git_status.toml".source = linkDotfile "starship/starship_no_git_status.toml";
    "starship_google3.toml".source = linkDotfile "starship/starship_google3.toml";
  };

  programs.fish = {
    functions.__select_starship_config = {
      body = ''
        if pwd | grep -q '^/google/src/cloud'
          set -gx STARSHIP_CONFIG ~/.config/starship_google3.toml
        else if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && not timeout 0.5s git status >/dev/null 2>&1
          set -gx STARSHIP_CONFIG ~/.config/starship_no_git_status.toml
        else
          set -gx STARSHIP_CONFIG ~/.config/starship.toml
        end
      '';
      onVariable = "PWD";
    };
    interactiveShellInit = ''
      if test -d /google && type -q starship
        __select_starship_config
      end
    '';
  };
}
