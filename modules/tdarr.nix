{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tdarr;

  # Function to generate the node-specific configuration
  mkNodeConfig = name: nodeCfg: {
    nodeName = nodeCfg.name;
    serverURL = "http://${cfg.serverIP}:${toString cfg.serverPort}";
    serverIP = cfg.serverIP;
    serverPort = toString cfg.serverPort;
    handbrakePath = "${pkgs.handbrake}/bin/HandBrakeCLI";
    ffmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
    mkvpropeditPath = "${pkgs.mkvtoolnix}/bin/mkvpropedit";
    pathTranslators = nodeCfg.pathTranslators;
    nodeType = nodeCfg.type;
    unmappedNodeCache = if nodeCfg.unmappedCache != "" then nodeCfg.unmappedCache else "${nodeCfg.dataDir}/cache";
    priority = nodeCfg.priority;
    cronPluginUpdate = "";
    apiKey = cfg.auth.apiKey;
    maxLogSizeMB = cfg.maxLogSizeMB;
    pollInterval = nodeCfg.pollInterval;
    startPaused = nodeCfg.startPaused;
  } // cfg.extraNodeConfig;

  serverDataDir = "${cfg.dataDir}/server";

in {
  options.services.tdarr = {
    enable = mkEnableOption "Tdarr distributed transcoding system";

    package = mkOption {
      type = types.package;
      default = pkgs.tdarr;
      description = "Tdarr package to use";
    };

    serverPort = mkOption {
      type = types.port;
      default = 8266;
      description = "Tdarr server API port";
    };

    webUIPort = mkOption {
      type = types.port;
      default = 8265;
      description = "Tdarr web UI port";
    };

    serverIP = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Server bind address";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/tdarr";
      description = "Base directory for Tdarr data";
    };

    enableCCExtractor = mkOption {
      type = types.bool;
      default = false;
      description = "Enable CCExtractor for closed caption extraction";
    };

    maxLogSizeMB = mkOption {
      type = types.int;
      default = 10;
      description = "Maximum log file size in MB";
    };

    auth = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable authentication";
      };
      secretKey = mkOption {
        type = types.str;
        default = "";
        description = "Secret key for authentication";
      };
      apiKey = mkOption {
        type = types.str;
        default = "";
        description = "API key for node authentication";
      };
    };

    nodes = mkOption {
      default = {};
      description = "Attribute set of Tdarr nodes to run on this machine.";
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          enable = mkEnableOption "this Tdarr node" // { default = true; };
          name = mkOption {
            type = types.str;
            default = "${config.networking.hostName}-${name}";
            description = "Name for this specific Tdarr node";
          };
          dataDir = mkOption {
            type = types.path;
            default = "${cfg.dataDir}/nodes/${name}";
            description = "Specific data directory for this node";
          };
          type = mkOption {
            type = types.enum [ "mapped" "unmapped" ];
            default = "mapped";
            description = "Node type - mapped or unmapped";
          };
          unmappedCache = mkOption {
            type = types.str;
            default = "";
            description = "Path for unmapped node cache";
          };
          priority = mkOption {
            type = types.int;
            default = -1;
            description = "Node priority";
          };
          pollInterval = mkOption {
            type = types.int;
            default = 2000;
            description = "Polling interval in ms";
          };
          startPaused = mkOption {
            type = types.bool;
            default = false;
            description = "Start node in paused state";
          };
          pathTranslators = mkOption {
            type = types.listOf (types.submodule {
              options = {
                server = mkOption { type = types.str; };
                node = mkOption { type = types.str; };
              };
            });
            default = [];
            description = "Path translations between server and node";
          };
        };
      }));
    };

    extraServerConfig = mkOption {
      type = types.attrs;
      default = {};
    };

    extraNodeConfig = mkOption {
      type = types.attrs;
      default = {};
    };

    user = mkOption {
      type = types.str;
      default = "tdarr";
    };

    group = mkOption {
      type = types.str;
      default = "tdarr";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };
    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 ${cfg.user} ${cfg.group} -"
      "d ${serverDataDir} 0755 ${cfg.user} ${cfg.group} -"
    ] ++ (mapAttrsToList (n: v: "d ${v.dataDir} 0755 ${cfg.user} ${cfg.group} -") cfg.nodes);

    # We merge the server service and the dynamic node services into one attribute set
    systemd.services = {
      tdarr-server = {
        description = "Tdarr Server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment.rootDataPath = serverDataDir;
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          ExecStartPre = pkgs.writeShellScript "tdarr-server-pre" ''
            mkdir -p ${serverDataDir}/configs
            ${pkgs.coreutils}/bin/install -m 644 ${pkgs.writeText "Tdarr_Server_Config.json" (builtins.toJSON ({
              serverPort = toString cfg.serverPort;
              webUIPort = toString cfg.webUIPort;
              serverIP = cfg.serverIP;
              serverBindIP = false;
              handbrakePath = "${pkgs.handbrake}/bin/HandBrakeCLI";
              ffmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
              mkvpropeditPath = "${pkgs.mkvtoolnix}/bin/mkvpropedit";
              ccextractorPath = optionalString cfg.enableCCExtractor "${pkgs.ccextractor}/bin/ccextractor";
              openBrowser = false;
              auth = cfg.auth.enable;
              authSecretKey = cfg.auth.secretKey;
              maxLogSizeMB = cfg.maxLogSizeMB;
            } // cfg.extraServerConfig))} ${serverDataDir}/configs/Tdarr_Server_Config.json
          '';
          ExecStart = "${cfg.package}/bin/tdarr-server";
          ReadWritePaths = [ cfg.dataDir ];
          Restart = "on-failure";
        };
      };
    } // (mapAttrs' (nodeId: nodeCfg: nameValuePair "tdarr-node-${nodeId}" (mkIf nodeCfg.enable {
      description = "Tdarr Node - ${nodeCfg.name}";
      after = [ "network.target" "tdarr-server.service" ];
      wants = [ "tdarr-server.service" ];
      wantedBy = [ "multi-user.target" ];
      environment.rootDataPath = nodeCfg.dataDir;
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStartPre = pkgs.writeShellScript "tdarr-node-${nodeId}-pre" ''
          mkdir -p ${nodeCfg.dataDir}/configs
          ${pkgs.coreutils}/bin/install -m 644 ${pkgs.writeText "Tdarr_Node_Config_${nodeId}.json" (builtins.toJSON (mkNodeConfig nodeId nodeCfg))} ${nodeCfg.dataDir}/configs/Tdarr_Node_Config.json
        '';
        ExecStart = "${cfg.package}/bin/tdarr-node";
        ReadWritePaths = [ cfg.dataDir ];
        Restart = "on-failure";
      };
    })) cfg.nodes);

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.serverPort cfg.webUIPort ];
  };
}
