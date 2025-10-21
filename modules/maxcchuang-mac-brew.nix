{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [ "mas" "media-control" ];
    casks = [
      "1password"
      "1password-cli"
      "alfred"
      "discord"
      "espanso"
      "fantastical"
      "hammerspoon"
      "heptabase"
      "iina"
      "jordanbaird-ice"
      "kitty"
      "logi-options+"
      "obsidian"
      "raycast"
      "spotify"
      "thingsmacsandboxhelper"
      "visual-studio-code"
      "zen"
    ];
    masApps = {
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
