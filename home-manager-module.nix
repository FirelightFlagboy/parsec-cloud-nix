self: { lib, pkgs, config, ... }:

let
  clientDefaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.parsec-cloud-v2-client;
  srcPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.parsec-cloud-v2-src;
in
{
  options.programs.parsec-cloud-client = with lib; {
    enable = mkEnableOption "parsec-cloud-client";

    package = mkOption {
      type = types.package;
      default = clientDefaultPackage;
      defaultText = lib.literalExpression ''
        parsec-cloud.packages.''${pkgs.stdenv.hostPlatform.system}.parsec-cloud-client
      '';
      description = mdDoc ''
        Parsec-cloud client package to use. Defaults to the one provided by the flake.
      '';
    };

    telemetry = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = "Wheter to enable telemetry";
    };

    lang = mkOption {
      type = types.str;
      default = "en";
      example = "fr";
      description = "Language to use";
    };

    preferredServer = mkOption {
      type = types.str;
      default = "parsec://saas.parsec.cloud";
      example = "parsec://myserver.com";
      description = "Preferred server to create organization to";
    };

    dataBaseDir = mkOption {
      type = types.path;
      default = "${config.xdg.dataHome}/parsec";
      example = "~/.parsec/data";
      description = "Directory to store data";
    };

    mountpoint = {
      baseDir = mkOption {
        # In reality, this value could be null and it will default to ~/Parsec.
        # but instead we use the default value of the option to make it explicit.
        type = types.path;
        default = "${config.home.homeDirectory}/Parsec";
        example = "~/Documents/Parsec";
        description = "Directory to mount your parsec workspaces";
      };

      enable = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = mdDoc ''
          Enable or disable mountpoint

          > Note: The application will enable that option on certain commands (like starting the GUI)
        '';
      };
    };

    firstLaunchMessage = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Display first launch's welcome message";
    };

    sentry = {
      dsn = mkOption {
        type = types.str;
        default = "https://863e60bbef39406896d2b7a5dbd491bb@o155936.ingest.sentry.io/1212848";
        example = "https://foobar.ingest.my-sentry-dsn.com/random_id";
        description = "Sentry DSN";
      };
      environment = mkOption {
        type = types.str;
        default = "production";
        example = "staging";
        description = "Sentry environment";
      };
    };


    preventSyncPatternFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "~/.config/parsec/custom-prevent-sync-pattern";
      description = mdDoc ''
        File containing file pattern that we don't want to sync.
        The file format is similar to `.gitignore`.
      '';
    };

    backend = {
      maxCooldown = mkOption {
        type = types.int;
        default = 30;
        example = 60;
        description = "Maximum duration between reconnection attempts in case of a connection lost with the server";
      };
      keepAlive = mkOption {
        # In reality that option could be null and it will default to 29.
        type = types.int;
        default = 29;
        example = 15;
        description = "interval in seconds between keepalive messages sent to the server";
      };
      maxConnections = mkOption {
        # TODO: Assert the value is greater or equal to 2
        type = types.int;
        default = 4;
        example = 8;
        description = "Maximum connections to the server";
      };
    };

    personalWorkspace = {
      baseDir = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "~/Documents/Parsec/Personal";
        description = "Directory to store personal workspaces";
      };
      namePattern = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "PersonalWorkspace";
        description = "Pattern of personal workspaces";
      };
    };

    workspaceStorageCacheSize = mkOption {
      type = types.int;
      default = 512 * 1024 * 1024;
      example = 1024 * 1024 * 1024;
      description = "Size of the workspace storage cache";
    };

    lastDevice = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "30ceb836cc786ea71605698c45f6d62a0dd4a0ab7fe3a379380a6ca0a4146d0a";
      description = mdDoc ''
        The ID of the last device used.
        This will put the said device at the top of the list of devices.

        > The id of a device can be retrieved with `parsec core list_devices`.
      '';
    };

    enableTray = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = "Allow to put the application in the system tray";
    };

    version = {
      last = mkOption {
        type = types.nullOr types.str;
        default = null;
        # example = builtins.toString clientDefaultPackage.version;
        example = lib.debug.traceSeq clientDefaultPackage.version "0.0.1";
        description = "Last version of the application used";
      };

      checkForUpdate = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = "Check for update on start";
      };

      allowPreRelease = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "Allow pre-release version when checking for new version";
      };

      apiURL = mkOption {
        type = types.str;
        default = "https://api.github.com/repos/Scille/parsec-cloud/releases";
        description = "API URL to check for update";
      };
    };

    gui = {
      askBeforeClose = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = "Ask for confirmation before closing the application";
      };

      showConfined = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = mdDoc ''
          Show confined files in the file manager.

          > Confined files are not synced with the server.
        '';
      };

      geometry = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Geometry of the GUI encoded in base64 to be used when starting up";
      };

      hideUnmounted = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "Hide unmounted workspaces in the GUI";
      };
    };
  };

  config =
    let
      cfgClient = config.programs.parsec-cloud-client;
      client = cfgClient.package;
    in
    lib.mkIf cfgClient.enable {
      home.packages = [ client ];

      # Parsec cloud configuration can be found here.
      # https://github.com/Scille/parsec-cloud/blob/d639f80bc10fb0dff506ac123b3eb205f23e1690/parsec/core/config.py#L48-L197
      xdg.configFile."parsec/config.json".text = builtins.toJSON {
        data_base_dir = cfgClient.dataBaseDir;
        prevent_sync_pattern = cfgClient.preventSyncPatternFile;
        preferred_org_creation_backend_addr = cfgClient.preferredServer;
        debug = false;

        backend_max_cooldown = cfgClient.backend.maxCooldown;
        backend_connection_keepalive = cfgClient.backend.keepAlive;
        backend_max_connections = cfgClient.backend.maxConnections;

        mountpoint_enabled = cfgClient.mountpoint.enable;
        mountpoint_base_dir = cfgClient.mountpoint.baseDir;

        personal_workspace_base_dir = cfgClient.personalWorkspace.baseDir;
        personal_workspace_name_pattern = cfgClient.personalWorkspace.namePattern;

        disabled_workspaces = [ ];

        sentry_dsn = cfgClient.sentry.dsn;
        sentry_environment = cfgClient.sentry.environment;
        telemetry_enabled = cfgClient.telemetry;

        workspace_storage_cache_size = cfgClient.workspaceStorageCacheSize;

        # This settings is only used with the smartcard extension.
        pki_extra_trust_roots = [ ];

        gui_last_device = cfgClient.lastDevice;
        gui_tray_enabled = cfgClient.enableTray;
        gui_language = cfgClient.lang;
        gui_first_launch = cfgClient.firstLaunchMessage;

        gui_last_version = cfgClient.version.last;
        gui_check_version_at_startup = cfgClient.version.checkForUpdate;
        gui_check_version_allow_pre_release = cfgClient.version.allowPreRelease;
        gui_check_version_api_url = cfgClient.version.apiURL;

        gui_confirmation_before_close = cfgClient.gui.askBeforeClose;
        gui_show_confined = cfgClient.gui.showConfined;
        gui_geometry = cfgClient.gui.geometry;
        gui_hide_unmounted = cfgClient.gui.hideUnmounted;

        # Only used on windows systems, but we define it anyway.
        ipc_win32_mutex_name = "parsec-cloud";
      };

      # TODO: Add icon
      xdg.dataFile."applications/parsec-cloud.desktop".text = ''
        [Desktop Entry]
        Name=Parsec
        Comment=Secure cloud framework
        Exec=${client}/bin/parsec core gui %u
        Icon=${srcPackage.icons}/parsec.png
        Terminal=false
        Type=Application
        Categories=Network;FileTransfer;Security;
        StartupNotify=false
        StartupWMClass=Parsec
        MimeType=x-scheme-handler/parsec
      '';
    };
}
