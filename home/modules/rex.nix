{ config, ... }:

{
  xdg.configFile."rex/init.lua".source = config.lib.custom.linkDotfile "rex/init.lua";

  # Nix shell initialization can replace the PATH Rex supplies to terminals.
  programs.fish.interactiveShellInit = ''
    if set -q REX_BIN_DIR
        fish_add_path --path --prepend --move $REX_BIN_DIR
    end
  '';
  programs.zsh.initContent = ''
    if [ -n "$REX_BIN_DIR" ]; then
      export PATH="$REX_BIN_DIR:$PATH"
    fi
  '';
}
