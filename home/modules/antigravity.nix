{ config, ... }:

{
  home.file.".gemini/config/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
}
