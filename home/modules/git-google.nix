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
    userName = "maxcchuang";
    userEmail = "maxcchuang@google.com";
    extraConfig = {
      http.cookiefile = "${config.home.homeDirectory}/.gitcookies";
    };
    includes = [
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
