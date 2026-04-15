{ homeDirectory }:
{ pkgs, ... }:
{
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      "/Applications/Ghostty.app"
      "/Applications/Google Chrome.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Google Chat.app"
      "/Applications/Gemini.app"
      "/Applications/Spotify.app"
      "/Applications/Pocket Casts.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Google Tasks.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Google Calendar.app"
    ];
    persistent-others = [
      "${homeDirectory}/Downloads"
      "${homeDirectory}/Desktop"
    ];
  };
}
