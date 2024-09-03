{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [ ];
    casks = [
      "hammerspoon"
      "ubersicht"
      "orbstack"
      "1password"
      "arc"
      "discord"
      "spotmenu"
      "spotify"
      "fantastical"
      "cleanshot"
      "jordanbaird-ice"
      "heptabase"
      "raycast"
      "thingsmacsandboxhelper"
    ];
    masApps = {
      "Things" = 904280696;
      "PastePal" = 1503446680;
      "RunCat" = 1429033973;
      "Keymapp" = 6472865291;
    };
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      extraFlags = [ "--verbose" "--debug" ];
    };
  };
}
