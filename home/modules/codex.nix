{ config, ... }:

let
  linkDotfile = config.lib.custom.linkDotfile;
in
{
  home.file = {
    ".codex/hooks/jj_guard.py".source = linkDotfile "codex/hooks/jj_guard.py";
    ".codex/hooks.json".source = linkDotfile "codex/hooks.json";
  };
}
