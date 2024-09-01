{ pkgs }: {
  system.defaults.dock.persistent-apps = [
    "/Applications/Google Chrome.app"
    "/Applications/Arc.app"
    "${pkgs.kitty}/Applications/kitty.app"
    "/Applications/Things3.app"
    "/Applications/Fantastical.app"
    "/Applications/Heptabase.app"
    "/System/Applications/Notes.app"
    "/Applications/Spotify.app"
  ];
}
