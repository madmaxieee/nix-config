{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [ "mas" "media-control" ];
    casks = [
      "1password"
      "1password-cli"
      "arc"
      "cleanshot"
      "discord"
      "espanso"
      "fantastical"
      "google-chrome"
      "hammerspoon"
      "heptabase"
      "iina"
      "jordanbaird-ice"
      "logi-options+"
      "nordvpn"
      "obsidian"
      "orbstack"
      "raycast"
      "spotify"
      "thingsmacsandboxhelper"
      "zen"
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
      cleanup = "zap";
      upgrade = true;
    };
  };
}
