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

  outputs = { self, nixpkgs, fenix, ... }@inputs:
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

      rust-toolchain = fenix.packages.${system}.stable.toolchain;

      poetry2nix = import inputs.poetry2nix {
        inherit pkgs;
      };
      # A prelease is denotted if version contain a hyphen.
      isPrerelease = version: pkgs.lib.strings.hasInfix "-" version;
    in
    {
      formatter.${ system} = pkgs.nixpkgs-fmt;

      packages.${system} =
        let
          parsec-cloud = {
            v2 =
              let
                version = "2.17.0";
                commit_sha256 = "1qaip52mmgfw6fqzrblzgxf4bbj19c5xl5carcn00q9a36y2mpvc";
              in
              rec {
                src = pkgs.fetchFromGitHub {
                  owner = "Scille";
                  repo = "parsec-cloud";
                  rev = "v${version}";
                  sha256 = commit_sha256;
                };
                patched-src = import packages/v2/patched-src { inherit pkgs version src; };
                client = import packages/v2/client.nix {
                  inherit pkgs poetry2nix system;
                  src = patched-src;
                };
              };
            v3 =
              let
                version = "3.1.0";
                # Currently parsec-cloud only provide a nightly release for v3 which change each day.
                # So fixing the commit_rev to stay on the same version.
                commit_rev = "2c0a049584088776a00ba7a639634c9d805c6140";
                # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz`
                commit_sha256 = "1wbdcgxmiv1kx4g3xjjvc14i2v9qjjmxdklpkhr0hcacs0zzaayh";
              in
              rec {
                src = pkgs.fetchFromGitHub {
                  owner = "Scille";
                  repo = "parsec-cloud";
                  rev = commit_rev;
                  sha256 = commit_sha256;
                };

                libparsec-node = import packages/v3/libparsec-node.nix { inherit pkgs version src rust-toolchain system; };
                native-build = import packages/v3/native-build.nix { inherit pkgs src version; isPrerelease = isPrerelease version; };
                client = import packages/v3/electron-app.nix {
                  inherit pkgs src;
                  client-build = native-build;
                  libparsec = libparsec-node;
                };
              };
          };
        in
        {
          parsec-cloud-v2-client = parsec-cloud.v2.client;
          parsec-cloud-v2-src = parsec-cloud.v2.patched-src;

          parsec-cloud-v3-node-lib = parsec-cloud.v3.libparsec-node;
          parsec-cloud-v3-native-build = parsec-cloud.v3.native-build;
          parsec-cloud-v3-client = parsec-cloud.v3.client;

          parsec-cloud-client = parsec-cloud.v3.client;
        };

      homeManagerModules = rec {
        parsec-cloud = {
          v2 = import packages/v2/home-manager-module.nix inputs.self;
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
            prefetch-npm-deps;
        };

        shellHook = ''
          echo "Good luck with your journey to nix (using flake)."
        '';
      };
    };
}
