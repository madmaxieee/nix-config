{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [ "mas" "media-control" ];
    casks = [
      "1password"
      "1password-cli"
      "alfred"
      "arc"
      "cleanshot"
      "discord"
      "espanso"
      "fantastical"
      "google-chrome"
      "hammerspoon"
      "heptabase"
      "iina"
      "inkscape"
      "jordanbaird-ice"
      "kitty"
      "logi-options+"
      "nordvpn"
      "obsidian"
      "orbstack"
      "raycast"
      "spotify"
      "stremio"
      "thingsmacsandboxhelper"
      "visual-studio-code"
      "zen"
    ];
    masApps = {
      "Keymapp" = 6472865291;
      "LINE" = 539883307;
      "PastePal" = 1503446680;
      "RunCat" = 1429033973;
      "Telegram" = 747648890;
      "Things" = 904280696;
    };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
  };
}
