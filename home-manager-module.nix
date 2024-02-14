self: { lib, pkgs, config, ... }:

let
  clientDefaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.parsec-cloud-client;
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

    checkForUpdate = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = "Check for update on start";
    };

    firstLaunchMessage = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Display first launch's welcome message";
    };

    sentryDsn = mkOption {
      type = types.str;
      default = "https://863e60bbef39406896d2b7a5dbd491bb@o155936.ingest.sentry.io/1212848";
      example = "https://foobar.ingest.my-sentry-dsn.com/random_id";
      description = "Sentry DSN";
    };

    sentryEnvironment = mkOption {
      type = types.str;
      default = "production";
      example = "staging";
      description = "Sentry environment";
    };
  };

  config =
    let
      cfgClient = config.programs.parsec-cloud-client;
      clientFinalPackage = cfgClient.package;
      client = pkgs.symlinkJoin {
        name = "parsec-cloud-client";
        paths = [ clientFinalPackage ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          set -x
          echo out=$out
          ls -lR $out
          wrapProgram "$out/bin/parsec" \
            --set PARSEC_SENTRY_DSN ${cfgClient.sentryDsn} \
            --set PARSEC_SENTRY_ENVIRONMENT ${cfgClient.sentryEnvironment}
        '';
      };
    in
    lib.mkIf cfgClient.enable {
      home.packages = [ client ];

      xdg.configFile."parsec/config.json".text = builtins.toJSON {
        telemetry_enabled = cfgClient.telemetry;
        gui_language = cfgClient.lang;
        preferred_org_creation_backend_addr = cfgClient.preferredServer;
        data_base_dir = cfgClient.dataBaseDir;
        gui_check_version_at_startup = cfgClient.checkForUpdate;
      };

      # TODO: Add icon
      xdg.dataFile."applications/parsec-cloud.desktop".text = ''
        [Desktop Entry]
        Name=Parsec
        Comment=Secure cloud framework
        Exec=${client} core gui %u
        Terminal=false
        Type=Application
        Categories=Network;FileTransfer;Security;
        StartupNotify=false
        StartupWMClass=Parsec
        MimeType=x-scheme-handler/parsec
      '';
    };
}
