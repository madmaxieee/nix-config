{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [ "zig" ];
    casks = [
      "hammerspoon"
      "orbstack"
      "1password"
      "arc"
      "discord"
      "spotify"
      "fantastical"
      "jordanbaird-ice"
      "cleanshot"
      "heptabase"
      "raycast"
      "thingsmacsandboxhelper"
      "scroll-reverser"
      "iina"
      "nordvpn"
      "obsidian"
      "logi-options-plus"
    ];
    masApps = {
      "Things" = 904280696;
      "PastePal" = 1503446680;
      "RunCat" = 1429033973;
      "Keymapp" = 6472865291;
      "Messenger" = 1480068668;
      "LINE" = 539883307;
    };
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      extraFlags = [ "--verbose" "--debug" ];
    };
  };
}
