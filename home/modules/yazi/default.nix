{ pkgs, ... }:
let
  plugins-repo = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "4a6edc3349a2a9850075363965d05b9063817df4";
    hash = "sha256-RYa7wbFGZ9citYYdF9FYJwzUGBmIUvNBdORpBPb6ZnQ=";
  };
in {
  home.packages = with pkgs; [ lazygit starship glow ];
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    initLua = ./init.lua;
    plugins = {
      git = "${plugins-repo}/git.yazi";
      full-border = "${plugins-repo}/full-border.yazi";
      smart-filter = "${plugins-repo}/smart-filter.yazi";
      starship = pkgs.fetchFromGitHub {
        owner = "Rolv-Apneseth";
        repo = "starship.yazi";
        rev = "af8bf6f82165b83272b6501ce7445cf2c61fbf51";
        hash = "sha256-L7MkZZqJ+t+A61ceC4Q1joLF6ytoWdgx9BwZWAGAoCA=";
      };
      lazygit = pkgs.fetchFromGitHub {
        owner = "Lil-Dank";
        repo = "lazygit.yazi";
        rev = "c82794fb410cca36b23b939d32126a6a9705f94d";
        hash = "sha256-m2zITkjGrUjaPnzHnnlwA6d4ODIpvlBfIO0RZCBfL0E=";
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
          on = "F";
          run = "plugin smart-filter";
          desc = "Smart filter";
        }
        {
          on = [ "g" "i" ];
          run = "plugin lazygit";
          desc = "run lazygit";
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
