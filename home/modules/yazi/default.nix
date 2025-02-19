{ pkgs, ... }:
let
  plugins-repo = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "beb586aed0d41e6fdec5bba7816337fdad905a33";
    hash = "sha256-enIt79UvQnKJalBtzSEdUkjNHjNJuKUWC4L6QFb3Ou4=";
  };
in {
  home.packages = with pkgs; [ lazygit glow ];
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    initLua = ./init.lua;
    plugins = {
      git = "${plugins-repo}/git.yazi";
      smart-enter = "${plugins-repo}/smart-enter.yazi";
      smart-filter = "${plugins-repo}/smart-filter.yazi";
      lazygit = pkgs.fetchFromGitHub {
        owner = "Lil-Dank";
        repo = "lazygit.yazi";
        rev = "9f924e34cde61d5965d6d620698b0b15436c8e08";
        hash = "sha256-ns9DzIdI2H3IuCByoJjOtUWQQB9vITxmJ/QrYt+Rdao=";
      };
      what-size = pkgs.fetchFromGitHub {
        owner = "pirafrank";
        repo = "what-size.yazi";
        rev = "b23e3a4cf44ce12b81fa6be640524acbd40ad9d3";
        hash = "sha256-SDObD22u2XYF2BYKsdw9ZM+yJLH9xYTwSFRWIwMCi08=";
      };
    };
    settings = {
      plugin.prepend_fetchers = [
        {
          id = "git";
          name = "*";
          run = "git";
        }
        {
          id = "git";
          name = "*/";
          run = "git";
        }
      ];
    };
    keymap = {
      manager.prepend_keymap = [
        {
          on = "<enter>";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = "f";
          run = "plugin smart-filter";
          desc = "Smart filter";
        }
        {
          on = "F";
          run = "filter";
          desc = "Filter";
        }
        {
          on = [ "g" "i" ];
          run = "plugin lazygit";
          desc = "run lazygit";
        }
        {
          on = [ "g" "?" ];
          run = "help";
          desc = "help";
        }
        {
          on = [ "." "s" ];
          run = "plugin what-size";
          desc = "Calc size of selection or cwd";
        }
      ];
    };
  };
}
