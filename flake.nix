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
          parsec-cloud = {
            v3 =
              let
                callPackage = pkgs.lib.callPackageWith (pkgs // package);
                package = rec {
                  version = "3.6.0";
                  # Currently parsec-cloud only provide a nightly release for v3 which change each day.
                  # So fixing the commit_rev to stay on the same version.
                  commit_rev = "d541d7886fdf33d045eb91b16552bd2b66962df4";
                  # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz`
                  commit_sha256 = "16f0lga1lg10g50js3w72r0788mgns757xbyqpiba6flf6il5xwj";

                  inherit rust-toolchain system;
                  isPrerelease = isVersionPrerelease version;

                  src = callPackage packages/v3/source.nix { };
                  libparsec-node = callPackage packages/v3/libparsec-node.nix { };
                  native-client-build = callPackage packages/v3/native-build.nix { };
                  client = callPackage packages/v3/electron-app.nix { };
                  cli = callPackage packages/v3/parsec-cli.nix { };
                };
              in
              package;
          };
        in
        {
          parsec-cloud-v3-src = parsec-cloud.v3.src;
          parsec-cloud-v3-node-lib = parsec-cloud.v3.libparsec-node;
          parsec-cloud-v3-native-client-build = parsec-cloud.v3.native-client-build;
          parsec-cloud-v3-client = parsec-cloud.v3.client;
          parsec-cloud-v3-cli = parsec-cloud.v3.cli;

          parsec-cloud-client = parsec-cloud.v3.client;
          parsec-cloud-cli = parsec-cloud.v3.cli;
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
