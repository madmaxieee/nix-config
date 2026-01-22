{ config, ... }: {
  xdg.configFile = {
    "git/mss_gitmessage.txt".text = ''
      {module_name (lower-case)}: {summary (1 line; <=50 chars; no ‘.’)}

      {Long description, wrap new line every 72 characters, use punctuation (optional)}

      Bug: {bug id}
      Test: {test cases performed, with punctuation}
      Doc: {Design docs, manual, … (optional)}
    '';
  };

  programs.git = {
    settings = {
      user = {
        name = "maxcchuang";
        email = "maxcchuang@google.com";
      };
      extraConfig = {
        http.cookiefile = "${config.home.homeDirectory}/.gitcookies";
      };
    };
    includes = [
      {
        condition = "hasconfig:remote.*.url:git@github.com:madmaxieee/**";
        contentSuffix = "personal";
        contents = {
          user = {
            name = "madmaxieee";
            email = "76544194+madmaxieee@users.noreply.github.com";
          };
        };
      }
      {
        condition = "hasconfig:remote.*.url:sso://*android/**";
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
