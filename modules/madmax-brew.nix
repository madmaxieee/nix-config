{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [
      # keep-sorted start
      "mas"
      "media-control"
      "tailscale"
      # keep-sorted end
    ];
    casks = [
      # keep-sorted start
      "1password"
      "1password-cli"
      "adobe-digital-editions"
      "alfred"
      "arc"
      "calibre"
      "chatgpt"
      "cleanshot"
      "codex"
      "codex-app"
      "discord"
      "espanso"
      "fantastical"
      "gcloud-cli"
      "ghostty"
      "google-chrome"
      "hammerspoon"
      "iina"
      "inkscape"
      "jordanbaird-ice"
      "kitty"
      "kobo"
      "logi-options+"
      "madmaxieee/tap/taigi-telex"
      "meetingbar"
      "nordvpn"
      "obsidian"
      "opencode-desktop"
      "orbstack"
      "pocket-casts"
      "raindropio"
      "raycast"
      "responsively"
      "spotify"
      "stremio"
      "tailscale-app"
      "telegram"
      "thingsmacsandboxhelper"
      "visual-studio-code"
      "vorssaint"
      "zen"
      # keep-sorted end
    ];
    # masApps = {
    #   "Keymapp" = 6472865291;
    #   "LINE" = 539883307;
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
