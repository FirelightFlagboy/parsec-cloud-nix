self:
{
  lib,
  pkgs,
  config,
  ...
}:

{
  imports = [
    (lib.mkRenamedOptionModule
      [
        "programs"
        "parsec-cloud-v3-client"
      ]
      [
        "programs"
        "parsec-cloud"
        "client"
      ]
    )
  ];

  options.programs.parsec-cloud =
    let
      inherit (lib)
        mkEnableOption
        mkOption
        types
        mkPackageOption
        ;
      flakePkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      client = mkOption {
        type = types.submodule {
          options.enable = mkEnableOption "parsec cloud client";
          options.package = mkPackageOption flakePkgs "parsec-cloud.v3.client" {
            extraDescription = ''
              Parsec-cloud client package to use. Defaults to the one provided by the flake.
            '';
          };
        };
      };
    };

  config =
    let
      cfgClient = config.programs.parsec-cloud.client;
      client = cfgClient.package;
      clientMajorVersion = lib.versions.major client.version;
      icon = client.icon;
      desktopItem = pkgs.makeDesktopItem {
        name = "parsec-cloud-v${clientMajorVersion}";
        desktopName = "Parsec Cloud v${clientMajorVersion}";
        comment = "Secure cloud framework";
        exec = "${client}/bin/parsec %U";
        inherit icon;
        terminal = false;
        categories = [
          "Office"
          "FileTransfer"
          "Filesystem"
          "Security"
        ];
        mimeTypes = [ "x-scheme-handler/parsec${clientMajorVersion}" ];
      };
    in
    lib.mkIf cfgClient.enable {
      home.packages = [
        client
        desktopItem
      ];
    };
}
