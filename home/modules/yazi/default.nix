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
        rev = "77a65f5a367f833ad5e6687261494044006de9c3";
        hash = "sha256-sAB0958lLNqqwkpucRsUqLHFV/PJYoJL2lHFtfHDZF8=";
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
        rev = "f08f7f2d5c94958ac4cb66c51a7c24b4319c6c93";
        hash = "sha256-q0CKA8OTMgr8hCZ3CM/Jd/Gv4y68uJdMFeHhhJyHcbI=";
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
