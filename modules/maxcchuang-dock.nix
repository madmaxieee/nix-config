{ pkgs, homeDirectory }: {
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      "${pkgs.kitty}/Applications/kitty.app"
      "/Applications/Google Chrome.app"
      "/Applications/Arc.app"
      "/Applications/Things3.app"
      "/Applications/Fantastical.app"
      "/Applications/Heptabase.app"
      "/System/Applications/Notes.app"
      "/Applications/Spotify.app"
    ];
    persistent-others =
      [ "${homeDirectory}/Downloads" "${homeDirectory}/Desktop" ];
  };
}
