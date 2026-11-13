{ homeDirectory }:
{ pkgs, ... }:
{
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      "/Applications/Rex Beta.app"
      "/Applications/Ghostty.app"
      "/Applications/Zen.app"
      "/Applications/Helium.app"
      "/Applications/T3 Code (Beta).app"
      "/Applications/ChatGPT.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Messenger.app"
      "/Applications/Telegram.app"
      "/Applications/Spotify.app"
      "/Applications/Pocket Casts.app"
      "/Applications/Things3.app"
      "/Applications/Fantastical.app"
      "/System/Applications/Notes.app"
    ];
    persistent-others = [ "${homeDirectory}/Downloads" ];
  };
}
