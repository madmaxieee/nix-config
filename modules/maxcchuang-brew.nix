{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [ ];
    casks = [
      "hammerspoon"
      "1password"
      "arc"
      "discord"
      "spotify"
      "fantastical"
      "jordanbaird-ice"
      "heptabase"
      "raycast"
      "thingsmacsandboxhelper"
      "iina"
      "obsidian"
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
