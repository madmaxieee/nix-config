{
  config,
  lib,
  pkgs,
  custom,
  ...
}:

let
  linkDotfile = config.lib.custom.linkDotfile;
  profile = custom.profile;
  atuinAiServer = pkgs.callPackage ../../packages/atuin-ai-server.nix { };
  atuinAiConfigPath = "${config.xdg.configHome}/atuin-ai/config.toml";
in
{
  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
    daemon.enable = true;
    settings = {
      ai = {
        enabled = true;
      }
      // lib.optionalAttrs (profile == "work") {
        endpoint = "http://localhost:8889";
      };
    };
  };

  xdg.configFile = lib.mkIf (profile == "work") {
    "atuin-ai/config.toml".source = linkDotfile "atuin-ai/config-work.toml";
  };

  home.packages = lib.mkIf (profile == "work") [
    atuinAiServer
  ];

  systemd.user.services = lib.mkIf (profile == "work" && pkgs.stdenv.isLinux) {
    atuin-ai-server = {
      Unit = {
        Description = "Atuin AI Server (Work)";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${atuinAiServer}/bin/atuin_ai_server start";
        Restart = "always";
        RestartSec = 5;
        Environment = [
          "CHAT_CONFIG=${atuinAiConfigPath}"
          "PATH=${lib.makeBinPath [ pkgs.coreutils ]}:/usr/bin:/bin"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

  launchd.agents = lib.mkIf (profile == "work" && pkgs.stdenv.isDarwin) {
    atuin-ai-server = {
      enable = true;
      config = {
        ProgramArguments = [
          "${atuinAiServer}/bin/atuin_ai_server"
          "start"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/atuin-ai-server.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/atuin-ai-server.log";
        EnvironmentVariables = {
          CHAT_CONFIG = atuinAiConfigPath;
          PATH = "${lib.makeBinPath [ pkgs.coreutils ]}:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin";
        };
      };
    };
  };
}
