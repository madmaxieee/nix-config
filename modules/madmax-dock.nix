{ homeDirectory }:
{ pkgs, ... }: {
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      "/Applications/kitty.app"
      "/Applications/Arc.app"
      "/Applications/Helium.app"
      "/Applications/Messenger.app"
      "/Applications/Telegram.app"
      "/Applications/LINE.app"
      "/Applications/Spotify.app"
      "/Applications/Things3.app"
      "/Applications/Fantastical.app"
      "/Applications/Heptabase.app"
      "/Applications/Discord.app"
      "/System/Applications/Podcasts.app"
    ];
    persistent-others = [ "${homeDirectory}/Downloads" ];
  };
}
