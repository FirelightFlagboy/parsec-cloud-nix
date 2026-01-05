{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      fenix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
          builders-use-substitutes = true;
          substituters = [
            "https://parsec-cloud.cachix.org"
            "https://cache.nixos.org"
          ];
          trusted-public-keys = [
            "parsec-cloud.cachix.org-1:MuWfCBKBfuUWqwB6xKFK0armIJ+A+Mi++HohuB6YvTk="
          ];
        };
      };

      rust-toolchain = fenix.packages.${system}.stable.minimalToolchain;

      # A pre-release is denoted if version contain a hyphen.
      isVersionPrerelease = version: pkgs.lib.strings.hasInfix "-" version;
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;

      packages.${system} =
        let
          makeDeprecatedPkg =
            parsec: attr: builtins.warn "Deprecated: Use `parsec-cloud.${attr}` instead" parsec.${attr};
        in
        rec {
          parsec-cloud = pkgs.callPackage packages/v3 {
            inherit system isVersionPrerelease rust-toolchain;
          };

          parsec-cloud-v3-src = makeDeprecatedPkg parsec-cloud "src";
          parsec-cloud-v3-node-lib = makeDeprecatedPkg parsec-cloud "libparsec-node";
          parsec-cloud-v3-native-client-build = makeDeprecatedPkg parsec-cloud "native-client-build";
          parsec-cloud-v3-client = makeDeprecatedPkg parsec-cloud "client";
          parsec-cloud-v3-cli = makeDeprecatedPkg parsec-cloud "cli";

          parsec-cloud-client = parsec-cloud-v3-client;
          parsec-cloud-cli = parsec-cloud-v3-cli;
        };

      homeManagerModules = rec {
        parsec-cloud = {
          v3 = import packages/v3/home-manager-module.nix inputs.self;
        };
        default = parsec-cloud.v3;
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = builtins.attrValues {
          inherit (pkgs)
            nixpkgs-fmt
            nil
            cachix
            gh
            prefetch-npm-deps
            ;
        };

        shellHook = ''
          echo "Good luck with your journey to nix (using flake)."
        '';
      };
    };
}
