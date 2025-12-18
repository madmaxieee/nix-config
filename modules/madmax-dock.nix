{ homeDirectory }:
{ pkgs, ... }: {
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      "/Applications/kitty.app"
      "/Applications/Arc.app"
      "/Applications/Helium.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Messenger.app"
      "/Applications/Telegram.app"
      "/Applications/Spotify.app"
      "/Applications/Things3.app"
      "/Applications/Fantastical.app"
      "/System/Applications/Podcasts.app"
    ];
    persistent-others = [ "${homeDirectory}/Downloads" ];
  };
}
