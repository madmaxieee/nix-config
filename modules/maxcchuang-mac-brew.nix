{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [
      # keep-sorted start
      "mas"
      "media-control"
      # keep-sorted end
    ];
    casks = [
      # keep-sorted start
      "1password"
      "1password-cli"
      "alfred"
      "discord"
      "espanso"
      "fantastical"
      "ghostty"
      "hammerspoon"
      "heptabase"
      "iina"
      "jordanbaird-ice"
      "kitty"
      "logi-options+"
      "meetingbar"
      "obsidian"
      "pocket-casts"
      "raindropio"
      "raycast"
      "spotify"
      "thingsmacsandboxhelper"
      "visual-studio-code"
      "zen"
      # keep-sorted end
    ];
    # masApps = {
    #   "KiteTasks" = 6759640044;
    #   "PastePal" = 1503446680;
    #   "RunCat" = 1429033973;
    #   "Things" = 904280696;
    # };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
  };
}
