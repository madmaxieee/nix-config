{ config, pkgs, ... }:

{
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    sd
    difftastic
    wget
    rm-improved

    parallel
    entr
    fzf
    jq
    lazygit
    just

    tealdeer
    typos

    kitty
  ];

  programs.fastfetch.enable = true;

  home.sessionVariables.PAGER = "bat -p";

  programs.fish = {
    shellAbbrs = {
      rm = "rip";
      rmm = "rm -rf";
      j = "just";
      lg = "lazygit";
    };
    shellAliases = {
      cat = "bat -p";
      l = "eza";
      ls = "eza --icons";
      la = "eza --icons --all";
      ll = "eza --icons --long --group";
      lla = "eza --icons --long --group --all";
      tree = "eza -T -a -I .git";
      icat = "kitten icat";
    };
  };
}
