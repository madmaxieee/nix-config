{ homeDirectory }:
{ pkgs, ... }: {
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      "/Applications/kitty.app"
      "/Applications/Google Chrome.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Google Chat.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Google Gemini.app"
      "/Applications/Spotify.app"
      "/Applications/Pocket Casts.app"
      "/Applications/Things3.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Google Calendar.app"
    ];
    persistent-others =
      [ "${homeDirectory}/Downloads" "${homeDirectory}/Desktop" ];
  };
}
