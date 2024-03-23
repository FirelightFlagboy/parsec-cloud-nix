{
  description = "A very basic flake";

  inputs = {
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }@inputs:
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

      poetry2nix = import inputs.poetry2nix {
        inherit pkgs;
      };

      parsec-cloud-version = "2.17.0";

      parsec-cloud-raw-src = pkgs.fetchFromGitHub {
        owner = "Scille";
        repo = "parsec-cloud";
        rev = "v${parsec-cloud-version}";
        sha256 = "1qaip52mmgfw6fqzrblzgxf4bbj19c5xl5carcn00q9a36y2mpvc";
      };
    in
    {
      formatter.${ system} = pkgs.nixpkgs-fmt;

      packages.${system} = rec {
        parsec-cloud-src = import packages/v2/patched-src { inherit pkgs parsec-cloud-raw-src parsec-cloud-version; };
        parsec-cloud-client = import packages/v2/client.nix {
          inherit pkgs parsec-cloud-src poetry2nix parsec-cloud-version system;
        };
      };

      homeManagerModules = rec {
        parsec-cloud = import ./home-manager-module.nix inputs.self;
        default = parsec-cloud;
      };

      devShells.${system}.default = with pkgs; mkShell {
        buildInputs = [
          nixpkgs-fmt
          nil
        ];

        shellHook = ''
          echo "Good luck with your journey to nix (using flake)."
        '';
      };
    };
}
