{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [ ];
    casks = [
      "hammerspoon"
      "orbstack"
      "1password"
      "arc"
      "discord"
      "spotmenu"
      "spotify"
      "fantastical"
      "jordanbaird-ice"
      "cleanshot"
      "heptabase"
      "raycast"
      "thingsmacsandboxhelper"
    ];
    masApps = {
      "Things" = 904280696;
      "PastePal" = 1503446680;
      "RunCat" = 1429033973;
      "Messenger" = 1480068668;
      "LINE" = 539883307;
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
