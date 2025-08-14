{ pkgs, ... }:
let
  plugins-repo = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "e95c7b384e7b0a9793fe1471f0f8f7810ef2a7ed";
    hash = "sha256-TUS+yXxBOt6tL/zz10k4ezot8IgVg0/2BbS8wPs9KcE=";
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
      smart-paste = "${plugins-repo}/smart-paste.yazi";
      lazygit = pkgs.fetchFromGitHub {
        owner = "Lil-Dank";
        repo = "lazygit.yazi";
        rev = "9f924e34cde61d5965d6d620698b0b15436c8e08";
        hash = "sha256-ns9DzIdI2H3IuCByoJjOtUWQQB9vITxmJ/QrYt+Rdao=";
      };
      searchjump = pkgs.fetchFromGitHub {
        owner = "DreamMaoMao";
        repo = "searchjump.yazi";
        rev = "7fafec3e667f2b93d3ad21989ef75bbf95bb43fc";
        hash = "sha256-zH/X7YUpfDiOcEKuXG4J1MZFj3Dv28rWOi9XEod8NNo=";
      };
      what-size = pkgs.fetchFromGitHub {
        owner = "pirafrank";
        repo = "what-size.yazi";
        rev = "d8966568f2a80394bf1f9a1ace6708ddd4cc8154";
        hash = "sha256-s2BifzWr/uewDI6Bowy7J+5LrID6I6OFEA5BrlOPNcM=";
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
      mgr.prepend_keymap = [
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
          on = "p";
          run = "plugin smart-paste";
          desc = "Paste into the hovered directory or CWD";
        }
        {
          on = "F";
          run = "filter";
          desc = "Filter";
        }
        {
          on = "s";
          run = "plugin searchjump";
          desc = "searchjump mode";
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
