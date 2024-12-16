{ config, ... }: {
  xdg.configFile = {
    "git/mss_gitmessage.txt".text = ''
      {module_name (lower-case)}: {summary (1 line; <=50 chars; no ‘.’)}

      Bug: {bug id}
      Fix: {bug id (optional)}

      {Long description, wrap new line every 72 characters, use punctuation (optional)}

      Test: {test cases performed, with punctuation}
      Doc: {Design docs, manual, … (optional)}
      Type: {Type: Choose one type of the following templates, and remove others}
      Type: bugfix
      Type: config
      Type: feature: {develop, enable, or disable}
      Type: code drop: {codebase}
      Type: hotfix#{number}: {codebase}
      CL dep: {Is dependent on AP change? (yes/no) (optional)}
    '';
  };

  programs.git = {
    userName = "Max Chuang";
    userEmail = "maxcchuang@google.com";
    extraConfig = {
      http.cookiefile = "${config.home.homeDirectory}/.gitcookies";
    };
    includes = [
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        contentSuffix = "github";
        contents = {
          user.name = "madmaxieee";
          user.email = "76544194+madmaxieee@users.noreply.github.com";
        };
      }
      {
        condition = "hasconfig:remote.*.url:ssh://soft/**";
        contentSuffix = "soft";
        contents = {
          user.name = "madmaxieee";
          user.email = "76544194+madmaxieee@users.noreply.github.com";
        };
      }
      {
        condition = "hasconfig:remote.*.url:sso:/*android/**";
        contentSuffix = "mss";
        contents = {
          commit.template = "${config.xdg.configHome}/git/mss_gitmessage.txt";
        };
      }
      {
        condition = "hasconfig:remote.*.url:https://*.googlesource.com/**";
        contentSuffix = "mss";
        contents = {
          commit.template = "${config.xdg.configHome}/git/mss_gitmessage.txt";
        };
      }
    ];
  };

}
