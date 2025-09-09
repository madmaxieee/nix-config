{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [ "mas" "media-control" ];
    casks = [
      "1password"
      "discord"
      "espanso"
      "fantastical"
      "hammerspoon"
      "heptabase"
      "iina"
      "jordanbaird-ice"
      "logi-options+"
      "obsidian"
      "raycast"
      "spotify"
      "thingsmacsandboxhelper"
      "zen"
    ];
    masApps = {
      "PastePal" = 1503446680;
      "RunCat" = 1429033973;
      "Things" = 904280696;
    };
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    global.autoUpdate = true;
  };
}
