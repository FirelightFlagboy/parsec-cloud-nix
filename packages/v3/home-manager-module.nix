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
      parsecPkgs = flakePkgs.parsec-cloud.v3;
      mkOptModule =
        ty:
        mkOption {
          type = types.submodule {
            options.enable = mkEnableOption "parsec cloud ${ty}";
            options.package = mkPackageOption parsecPkgs "${ty}" { };
          };
        };
    in
    {
      client = mkOptModule "client";
      cli = mkOptModule "cli";
    };

  config =
    let
      cfg = config.programs.parsec-cloud;
      cfgClient = cfg.client;
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
    {
      home.packages =
        (lib.lists.optionals cfgClient.enable [
          client
          desktopItem
        ])
        + (lib.lists.optionals cfg.cli.enable [ cfg.cli.package ]);
    };
}
