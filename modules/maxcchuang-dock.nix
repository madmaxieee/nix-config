{ pkgs, homeDirectory }: {
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      "${pkgs.kitty}/Applications/kitty.app"
      "/Applications/Google Chrome.app"
      "/Applications/Arc.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Google Chat.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Gemini.app"
      "/Applications/Spotify.app"
      "/Applications/Things3.app"
      "${homeDirectory}/Applications/Chrome Apps.localized/Google Calendar.app"
      "/Applications/Fantastical.app"
      "/Applications/Obsidian.app"
      "/Applications/Heptabase.app"
    ];
    persistent-others =
      [ "${homeDirectory}/Downloads" "${homeDirectory}/Desktop" ];
  };
}
