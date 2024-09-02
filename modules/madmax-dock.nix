{ pkgs }: {
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      "${pkgs.kitty}/Applications/kitty.app"
      "/Applications/Arc.app"
      "/Applications/Messenger.app"
      "/Applications/Telegram.app"
      "/Applications/LINE.app"
      "/Applications/Spotify.app"
      "/Applications/Things3.app"
      "/Applications/Fantastical.app"
      "/Applications/Heptabase.app"
      "/System/Applications/Notes.app"
      "/Applications/Discord.app"
      "/System/Applications/Podcasts.app"
      "/Applications/Steam.app"
    ];
    persistent-others = [ "~/Downloads" ];
  };
}
