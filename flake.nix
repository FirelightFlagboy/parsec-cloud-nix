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

        config.allowUnfree = true;
      };

      poetry2nix = import inputs.poetry2nix {
        inherit pkgs;
      };

      parsec-cloud-version = "2.16.3";

      parsec-cloud-raw-src = pkgs.fetchFromGitHub {
        owner = "Scille";
        repo = "parsec-cloud";
        rev = "v${parsec-cloud-version}";
        sha256 = "1ygkccny40sb2b7klia107z14zdfxhl07aagl51zx4ywpys2l8az";
      };

      parsec-cloud-src = import packages/parsec-cloud-src { inherit pkgs parsec-cloud-raw-src parsec-cloud-version; };
      parsec-cloud-client = import packages/parsec-cloud-client {
        inherit pkgs parsec-cloud-src poetry2nix parsec-cloud-version;
      };
    in
    {
      formatter.${ system} = pkgs.nixpkgs-fmt;

      packages.${system} = {
        inherit parsec-cloud-src parsec-cloud-client;
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
