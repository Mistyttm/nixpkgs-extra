{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.steam-presence;

  defaultPackage = pkgs.steam-presence or (pkgs.callPackage ../pkgs/steam-presence { });

  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with maintainers; [ mistyttm ];

  options.programs.steam-presence = {
    enable = mkEnableOption "Steam Presence for Discord";

    package = mkOption {
      type = types.package;
      default = defaultPackage;
      defaultText = literalExpression "pkgs.steam-presence";
      description = ''
        The Steam Presence package to use.

        This package displays your currently played Steam game in Discord
        using Discord Rich Presence.
      '';
    };

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to automatically start Steam Presence when the graphical session starts.

        When enabled, Steam Presence will run as a systemd user service and automatically
        start when you log in to your desktop environment.
      '';
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = {};
      description = "Settings to be written to the YAML config file for myService.";
    };

    secretSettingsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a YAML or JSON file containing secret values, managed by sops-nix.";
    };
  };

  config = mkIf cfg.enable {
    # Add the package to user's packages
    home.packages = [ cfg.package ];

    # Create config file if settings are provided
    home.file."~/.config/my-service/config.yaml".source = yamlFormat.generate "my-service-config.yaml" config.myService.settings;


    # Systemd user service for auto-starting
    systemd.user.services.steam-presence = mkIf cfg.autoStart {
      Unit = {
        Description = "Steam Presence for Discord";
        Documentation = "https://github.com/JustTemmie/steam-presence";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/steam-presence";
        Restart = "on-failure";
        RestartSec = "5s";

        # Environment variables that might be needed
        Environment = [
          "PATH=${makeBinPath [ pkgs.steam ]}"
        ];

        # Only restart a few times to prevent infinite restart loops
        StartLimitBurst = 3;
        StartLimitIntervalSec = 30;
      };
    };
  };
}
