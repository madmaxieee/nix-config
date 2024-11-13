{ pkgs, ... }: {
  home.packages = [ pkgs.yazi ];

  programs.fish.functions = {
    y = ''
      set tmp (mktemp -t "yazi-cwd.XXXXXX")
      yazi $argv --cwd-file="$tmp"
      if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
      end
      rm -f -- "$tmp"
    '';
  };

  programs.zsh.shellAliases = {
    y = ''
      local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd; yazi "$@" --cwd-file="$tmp"; cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"; rm -f -- "$tmp"
    '';
  };
}
