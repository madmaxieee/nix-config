{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    casks = [
      "1password"
      "arc"
      "cleanshot"
      "discord"
      "espanso"
      "fantastical"
      "hammerspoon"
      "heptabase"
      "iina"
      "jordanbaird-ice"
      "logi-options-plus"
      "nordvpn"
      "obsidian"
      "orbstack"
      "raycast"
      "spotify"
      "squirrel"
      "thingsmacsandboxhelper"
    ];
    masApps = {
      "Keymapp" = 6472865291;
      "LINE" = 539883307;
      "Messenger" = 1480068668;
      "PastePal" = 1503446680;
      "RunCat" = 1429033973;
      "Things" = 904280696;
    };
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      extraFlags = [ "--verbose" "--debug" ];
    };
  };
}
