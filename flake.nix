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
      self,
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

      rust-toolchain = fenix.packages.${system}.stable.toolchain;

      poetry2nix = import inputs.poetry2nix {
        inherit pkgs;
      };
      # A prelease is denotted if version contain a hyphen.
      isPrerelease = version: pkgs.lib.strings.hasInfix "-" version;
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;

      packages.${system} =
        let
          parsec-cloud = {
            v2 =
              let
                version = "2.17.0";
                commit_sha256 = "1qaip52mmgfw6fqzrblzgxf4bbj19c5xl5carcn00q9a36y2mpvc";
                callPackage = pkgs.lib.callPackageWith (pkgs // { inherit version; });
              in
              rec {
                src = pkgs.fetchFromGitHub {
                  owner = "Scille";
                  repo = "parsec-cloud";
                  rev = "v${version}";
                  sha256 = commit_sha256;
                };
                patched-src = callPackage packages/v2/patched-src { inherit src; };
                client = callPackage packages/v2/client.nix {
                  inherit poetry2nix;
                  src = patched-src;
                };
              };
            v3 =
              let
                version = "3.3.2";
                # Currently parsec-cloud only provide a nightly release for v3 which change each day.
                # So fixing the commit_rev to stay on the same version.
                commit_rev = "ea1fca30af6dc22bccd06c5cf9658c23e73eb179";
                # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz`
                commit_sha256 = "1jzx2dhjs4pv6v8xfl7q5w2d2l64nz8wgzglpgwj27yx946ph9x2";
                callPackage = pkgs.lib.callPackageWith (pkgs // package);
                package = {
                  inherit version rust-toolchain system;
                  isPrerelease = isPrerelease version;
                  src = pkgs.fetchFromGitHub {
                    owner = "Scille";
                    repo = "parsec-cloud";
                    rev = commit_rev;
                    sha256 = commit_sha256;
                  };
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
          parsec-cloud-v2-client = parsec-cloud.v2.client;
          parsec-cloud-v2-src = parsec-cloud.v2.patched-src;

          parsec-cloud-v3-node-lib = parsec-cloud.v3.libparsec-node;
          parsec-cloud-v3-native-client-build = parsec-cloud.v3.native-client-build;
          parsec-cloud-v3-client = parsec-cloud.v3.client;
          parsec-cloud-v3-cli = parsec-cloud.v3.cli;

          parsec-cloud-client = parsec-cloud.v3.client;
          parsec-cloud-cli = parsec-cloud.v3.cli;
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
            prefetch-npm-deps
            ;
        };

        shellHook = ''
          echo "Good luck with your journey to nix (using flake)."
        '';
      };
    };
}
