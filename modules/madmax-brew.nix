{
  environment.systemPath = [ "/opt/homebrew/bin" ];
  homebrew = {
    enable = true;
    brews = [
      # keep-sorted start
      "mas"
      "media-control"
      "mole"
      # dependency of the gcloud-cli cask, keeps cleanup from removing it
      "python@3.14"
      "tailscale"
      # keep-sorted end
    ];
    casks = [
      # keep-sorted start
      "1password"
      "1password-cli"
      "adobe-digital-editions"
      "alfred"
      "anki"
      "antigravity"
      "antigravity-cli"
      "arc"
      "calibre"
      "chatgpt"
      "claude"
      "claude-code"
      "cloudflare-warp"
      "codex"
      "codex-app"
      "discord"
      "espanso"
      "fantastical"
      "gcloud-cli"
      "ghostty"
      "google-chrome"
      "google-gemini"
      "hammerspoon"
      "iina"
      "inkscape"
      "jordanbaird-ice"
      "kitty"
      "kobo"
      "lab421/tap/forel"
      "logi-options+"
      "meetingbar"
      "nordvpn"
      "obsidian"
      "orbstack"
      "pocket-casts"
      "raindropio"
      "raycast"
      "responsively"
      "spotify"
      "stremio"
      "t3-code"
      "taigikeyboard/tap/taigikeyboard"
      "tailscale-app"
      "telegram"
      "thingsmacsandboxhelper"
      "utm"
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
