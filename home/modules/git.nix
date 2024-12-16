{ pkgs, ... }:

{
  home.packages = with pkgs; [ difftastic ];

  programs.bat = {
    themes = {
      tokyonight-moon = {
        src = pkgs.fetchFromGitHub {
          owner = "folke";
          repo = "tokyonight.nvim";
          rev = "9758827c3b380ba89da4a2212b6255d01afbcf08";
          hash = "sha256-qEmfBs+rKP25RlS7VxNSw9w4GnlZiiEchs17nJg7vsE=";
        };
        file = "extras/sublime/tokyonight_moon.tmTheme";
      };
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    delta = {
      enable = true;
      options = {
        line-numbers = true;
        side-by-side = true;
        navigate = true;
        syntax-theme = "tokyonight-moon";
      };
    };

    aliases = {
      "st" = "status -sb";

      "a" = "add";
      "aa" = "add --all";
      "ua" = "restore --staged";

      "c" = "commit";
      "cm" = "commit -m";
      "amend" = "commit --amend";

      "d" = "diff";
      "ds" = "diff --staged";

      "f" = "fetch";
      "fa" = "fetch --all";

      "rb" = "rebase";
      "cp" = "cherry-pick";

      "p" = "push";
      "pushf" = "push --force-with-lease";

      "co" = "checkout";
      "sw" = "switch";
      "br" = "branch";
      "brl" = "branch -l";
      "brr" = "branch -r";
      "wt" = "worktree";

      "sa" = "stash apply";
      "ss" = "stash push";
      "sp" = "stash pop";
      "sl" =
        "stash list --pretty=format:'%C(red)%h%C(reset) - %C(dim yellow)(%C(bold magenta)%gd%C(dim yellow))%C(reset) %<(70,trunc)%s %C(green)(%cr) %C(bold blue)<%an>%C(reset)'";

      "lg" =
        "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      "llog" =
        "log --graph --name-status --pretty=format:'%C(red)%h %C(reset)(%cd) %C(green)%an %Creset%s %C(yellow)%d%Creset' --date=relative";
      "hist" =
        "log --pretty=format:'%Cgreen%h %Creset%cd %Cblue[%cn] %Creset%s%C(yellow)%d%C(reset)' --graph --date=relative --decorate --all";
      "rlog" =
        "reflog --pretty=format:'%Cred%h%Creset %C(auto)%gd%Creset %C(auto)%gs%C(reset) %C(green)(%cr)%C(reset) %C(bold blue)<%an>%Creset' --abbrev-commit";

      "sub" = "submodule";
      "zip" = "archive HEAD --output";
      "tgz" = "archive --format=tgz HEAD --output";
      "bs" = "bisect";
      "ls" = "ls-files";

      "ignore" = "update-index --skip-worktree";
      "noignore" = "update-index --no-skip-worktree";
    };

    ignores = (if pkgs.stdenv.isDarwin then [
      # General
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"

      # Icon must end with two \r
      "Icon\r\r"

      # Thumbnails
      "._*"

      # Files that might appear in the root of a volume
      ".DocumentRevisions-V100"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      ".com.apple.timemachine.donotpresent"

      # Directories potentially created on remote AFP share
      ".AppleDB"
      ".AppleDesktop"
      "Network Trash Folder"
      "Temporary Items"
      ".apdisk"
    ] else
      [ ]) ++ [
        # clangd
        ".cache"
        "compile_commands.json"

        # typos cli
        "typos.toml"
      ];

    extraConfig = {
      init.defaultBranch = "main";

      core.autocrlf = "false";

      pull.rebase = "true";
      push.autoSetupRemote = "true";

      diff.tool = "nvimdiff";
      difftool.prompt = false;
      "difftool \"nvimdiff\"".cmd = ''nvim -d "$LOCAL" "$REMOTE"'';

      merge.tool = "nvimdiff";
      mergetool.prompt = false;
      "mergetool \"nvimdiff\"".cmd = ''nvim -d "$LOCAL" "$REMOTE" "$MERGED"'';
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };
}
