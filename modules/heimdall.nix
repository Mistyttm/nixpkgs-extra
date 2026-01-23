{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.heimdall;

  # Create a custom PHP package with required extensions
  heimdallPhp = pkgs.php83.withExtensions (
    { enabled, all }:
    with all;
    enabled
    ++ [
      ctype
      curl
      dom
      fileinfo
      filter
      mbstring
      openssl
      pdo
      pdo_sqlite
      session
      tokenizer
      zip
    ]
  );

  user = "heimdall";
  group = "heimdall";

  # Generate runtime environment file that includes the secret
  envGenerator = pkgs.writeShellScript "generate-heimdall-env" ''
    set -e

    # Read the app key
    ${
      if cfg.appKeyFile != null then
        ''
          APP_KEY=$(cat "${cfg.appKeyFile}")
        ''
      else
        ''
          APP_KEY="${cfg.appKey}"
        ''
    }

    # Generate the .env file
    cat > "$1" <<EOF
    APP_NAME=Heimdall
    APP_ENV=production
    APP_KEY=$APP_KEY
    APP_DEBUG=false
    APP_URL=${cfg.appUrl}

    DB_CONNECTION=sqlite
    DB_DATABASE=${cfg.dataDir}/database.sqlite

    CACHE_DRIVER=file
    QUEUE_CONNECTION=sync
    SESSION_DRIVER=file
    SESSION_LIFETIME=120

    ${optionalString cfg.allowInternalRequests "ALLOW_INTERNAL_REQUESTS=true"}
    ${optionalString (cfg.appSource != null) "APP_SOURCE=${cfg.appSource}"}

    ${cfg.extraConfig}
    EOF

    chmod 640 "$1"
    chown ${user}:${group} "$1"
  '';

in
{
  options.services.heimdall = {
    enable = mkEnableOption "Heimdall application dashboard";

    package = mkOption {
      type = types.package;
      default = pkgs.heimdall;
      defaultText = literalExpression "pkgs.heimdall";
      description = "Heimdall package to use.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/heimdall";
      description = "Directory where Heimdall stores its data.";
    };

    appKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Application key for encryption. Generate with:
        php artisan key:generate --show

        Should be in the format: base64:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

        Leave null to use appKeyFile instead (recommended with sops-nix).
      '';
    };

    appKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "config.sops.secrets.heimdall-app-key.path";
      description = ''
        Path to file containing the application key.
        This is the recommended way to provide the key when using sops-nix.

        The file should contain only the key in the format:
        base64:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      '';
    };

    appUrl = mkOption {
      type = types.str;
      default = "http://localhost";
      example = "https://heimdall.example.com";
      description = "The URL where Heimdall will be accessible.";
    };

    allowInternalRequests = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Allow requests to internal/private IP addresses.
        Warning: This may expose your application to SSRF attacks.
      '';
    };

    appSource = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "http://localhost/";
      description = ''
        Custom URL for the apps list (for offline operation).
        Should point to the directory containing list.json.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration to add to the .env file.";
    };

    nginx = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable nginx virtual host configuration.";
      };

      hostName = mkOption {
        type = types.str;
        default = "heimdall.local";
        example = "heimdall.example.com";
        description = "Hostname for the nginx virtual host.";
      };

      enableSSL = mkOption {
        type = types.bool;
        default = false;
        description = "Enable SSL for the nginx virtual host.";
      };

      sslCertificate = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to SSL certificate.";
      };

      sslCertificateKey = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to SSL certificate key.";
      };
    };

    poolConfig = mkOption {
      type =
        with types;
        attrsOf (oneOf [
          str
          int
          bool
        ]);
      default = {
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 4;
        "pm.max_requests" = 500;
      };
      description = "Options for the Heimdall PHP pool.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.nginx.enableSSL -> (cfg.nginx.sslCertificate != null && cfg.nginx.sslCertificateKey != null);
        message = "SSL certificate and key must be provided when SSL is enabled.";
      }
      {
        assertion = (cfg.appKey != null) || (cfg.appKeyFile != null);
        message = "Either appKey or appKeyFile must be set.";
      }
      {
        assertion = !((cfg.appKey != null) && (cfg.appKeyFile != null));
        message = "Only one of appKey or appKeyFile should be set, not both.";
      }
      {
        assertion = (cfg.appKey == null) || (hasPrefix "base64:" cfg.appKey);
        message = "appKey must be a valid Laravel key starting with 'base64:'. Generate one with: php artisan key:generate --show";
      }
    ];

    users.users.${user} = {
      isSystemUser = true;
      group = group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${group} = { };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${user} ${group} - -"
      "d '${cfg.dataDir}/app' 0750 ${user} ${group} - -"
      "d '${cfg.dataDir}/storage' 0750 ${user} ${group} - -"
      "d '${cfg.dataDir}/storage/app' 0750 ${user} ${group} - -"
      "d '${cfg.dataDir}/storage/framework' 0750 ${user} ${group} - -"
      "d '${cfg.dataDir}/storage/framework/cache' 0750 ${user} ${group} - -"
      "d '${cfg.dataDir}/storage/framework/sessions' 0750 ${user} ${group} - -"
      "d '${cfg.dataDir}/storage/framework/views' 0750 ${user} ${group} - -"
      "d '${cfg.dataDir}/storage/logs' 0750 ${user} ${group} - -"
      "d '${cfg.dataDir}/uploads' 0750 ${user} ${group} - -"
      "f '${cfg.dataDir}/database.sqlite' 0640 ${user} ${group} - -"
      "f '${cfg.dataDir}/.env' 0640 ${user} ${group} - -"
    ];

    systemd.services.heimdall-init = {
      description = "Heimdall initialization";
      wantedBy = [ "multi-user.target" ];
      before = [ "phpfpm-heimdall.service" ];
      after = [ "network.target" ] ++ (optional (cfg.appKeyFile != null) "sops-nix.service");
      wants = optional (cfg.appKeyFile != null) "sops-nix.service";

      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "heimdall";
        StateDirectoryMode = "0750";
        User = user;
        Group = group;
        RemainAfterExit = true;
        ReadWritePaths = [ cfg.dataDir ];
      };

      script = ''
        set -e

        mkdir -p ${cfg.dataDir}/app ${cfg.dataDir}/storage ${cfg.dataDir}/uploads
        chown -R ${user}:${group} ${cfg.dataDir}
        chmod -R u+rwX ${cfg.dataDir}

        # Ensure writable app copy exists
        if [ ! -e ${cfg.dataDir}/app/.heimdall-installed ]; then
          cp -R ${cfg.package}/share/heimdall/* ${cfg.dataDir}/app/
          touch ${cfg.dataDir}/app/.heimdall-installed
        fi

        chown -R ${user}:${group} ${cfg.dataDir}
        chmod -R u+rwX ${cfg.dataDir}

        cd ${cfg.dataDir}/app

        # Generate the .env file with secrets
        ${envGenerator} ${cfg.dataDir}/.env

        # Link storage directories
        if [ ! -L storage ]; then
          rm -rf storage
          ln -sf ${cfg.dataDir}/storage storage
        fi

        # Link database
        if [ ! -L database/database.sqlite ]; then
          mkdir -p database
          ln -sf ${cfg.dataDir}/database.sqlite database/database.sqlite
        fi

        # Link uploads
        if [ ! -L public/backgrounds ]; then
          rm -rf public/backgrounds
          ln -sf ${cfg.dataDir}/uploads public/backgrounds
        fi

        # Link .env file
        ln -sf ${cfg.dataDir}/.env .env

        # Create database if it doesn't exist
        if [ ! -s ${cfg.dataDir}/database.sqlite ]; then
          ${heimdallPhp}/bin/php artisan migrate --force
        fi

        # Clear and cache configuration
        ${heimdallPhp}/bin/php artisan config:clear
        ${heimdallPhp}/bin/php artisan config:cache
        ${heimdallPhp}/bin/php artisan route:cache
        ${heimdallPhp}/bin/php artisan view:cache
      '';
    };

    services.phpfpm.pools.heimdall = {
      user = user;
      group = group;

      phpPackage = heimdallPhp;

      settings = {
        "listen.owner" = config.services.nginx.user;
        "listen.group" = config.services.nginx.group;
        "php_admin_value[memory_limit]" = "256M";
        "php_admin_value[upload_max_filesize]" = "30M";
        "php_admin_value[post_max_size]" = "30M";
      }
      // cfg.poolConfig;

      phpEnv = {
        HEIMDALL_ROOT = "${cfg.dataDir}/app";
      };
    };

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;

      virtualHosts.${cfg.nginx.hostName} = {
        root = "${cfg.dataDir}/app/public";

        extraConfig = ''
          index index.php;
          charset utf-8;
          client_max_body_size 30M;
        '';

        locations = {
          "/" = {
            tryFiles = "$uri $uri/ /index.php?$query_string";
          };

          "~ \\.php$" = {
            extraConfig = ''
              fastcgi_pass unix:${config.services.phpfpm.pools.heimdall.socket};
              fastcgi_index index.php;
              fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
              include ${pkgs.nginx}/conf/fastcgi_params;
              fastcgi_param PHP_VALUE "upload_max_filesize=30M \n post_max_size=30M";
            '';
          };

          "~ /\\.(?!well-known).*" = {
            return = "404";
          };
        };

        enableACME = cfg.nginx.enableSSL && (cfg.nginx.sslCertificate == null);
        forceSSL = cfg.nginx.enableSSL;

        sslCertificate = cfg.nginx.sslCertificate;
        sslCertificateKey = cfg.nginx.sslCertificateKey;
      };
    };
  };

  meta.maintainers = [ ];
}
