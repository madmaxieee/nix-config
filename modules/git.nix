{ ... }:

{
  programs.git = {
    enable = true;
    userName = "madmaxieee";
    userEmail = "76544194+madmaxieee@users.noreply.github.com";
    lfs.enable = true;
    delta.enable = true;
    aliases = {
      "st" = "status -sb";
      "a" = "add";
      "aa" = "add --all";
      "ua" = "restore --staged";
      "cm" = "commit -m";
      "cam" = "commit -a -m";
      "amend" = "commit --amend";
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
    };
    extraConfig = {
      init.defaultBranch = "main";

      core = {
        editor = "nvim";
        autocrlf = "false";
      };

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
