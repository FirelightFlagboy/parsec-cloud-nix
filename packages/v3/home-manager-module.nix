self: { lib, pkgs, config, ... }:

let
  clientDefaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.parsec-cloud-v3-client;
in
{
  options.programs.parsec-cloud-v3-client = with lib; {
    enable = mkEnableOption "parsec-cloud-v3-client";

    package = mkOption {
      type = types.package;
      default = clientDefaultPackage;
      defaultText = lib.literalExpression ''
        parsec-cloud.packages.${pkgs.stdenv.hostPlatform.system}.parsec-cloud-v3-client
      '';
      description = mdDoc ''
        Parsec-cloud client package to use. Defaults to the one provided by the flake.
      '';
    };
  };

  config =
    let
      cfgClient = config.programs.parsec-cloud-v3-client;
      client = cfgClient.package;
      clientMajorVersion = lib.versions.major client.version;
      icon = client.icon;
      desktopItem = pkgs.makeDesktopItem {
        name = "Parsec Cloud v${clientMajorVersion}";
        desktopName = "Parsec Cloud";
        comment = "Secure cloud framework";
        exec = "${client}/bin/parsec-v${clientMajorVersion} %U";
        inherit icon;
        terminal = false;
        categories = [ "Office" "FileTransfer" "Filesystem" "Security" ];
        mimeTypes = [ "x-scheme-handler/parsec${clientMajorVersion}" ];
      };
    in
    lib.mkIf cfgClient.enable {
      home.packages = [ client ];

      xdg.dataFile."applications/parsec-cloud-v${clientMajorVersion}.desktop".source = "${desktopItem}/share/applications/parsec-v${clientMajorVersion}.desktop";
    };
}
