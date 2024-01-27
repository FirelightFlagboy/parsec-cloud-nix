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
      };

      poetry2nix = import inputs.poetry2nix {
        inherit pkgs;
      };

      parsec-cloud-version = "2.16.3";

      parsec-cloud-src = pkgs.fetchFromGitHub {
        owner = "Scille";
        repo = "parsec-cloud";
        rev = "v${parsec-cloud-version}";
        sha256 = "1ygkccny40sb2b7klia107z14zdfxhl07aagl51zx4ywpys2l8az";
      };

      parsec-cloud-src-patched = pkgs.stdenv.mkDerivation {
        name = "parsec-cloud-src-patched";
        version = parsec-cloud-version;
        src = parsec-cloud-src;
        patches = [ patches/parsec-cloud-poetry-deps.patch ];
        patchFlags = "--strip=1 --verbose";
        # phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];
        # buildPhase = ''echo ">>>>>>>>>>> buildPhase"'';
        installPhase = ''
          mkdir -p $out
          cp -r $src/* $out
        '';
      };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;

      packages.${system} = {
        inherit parsec-cloud-src-patched;

        parsec-cloud-client = poetry2nix.mkPoetryApplication
          {
            projectDir = parsec-cloud-src-patched;
            extras = [ "core" ];
            # preferWheels = true;
            checkGroups = [ "test" ];
            python = pkgs.python39;
            nativeBuildInputs = [ pkgs.qt5.wrapQtAppsHook pkgs.patchelf ];

            overrides = poetry2nix.overrides.withDefaults
              (self: super: {
                pywin32 = null;
                patchelf = null;
                # patchelf = super.patchelf.overridePythonAttrs (old: {
                #   nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.cmake ];
                #   buildInputs = old.buildInputs ++ [ super.setuptools super.setuptools-scm super.scikit-build ];
                # });
                winfspy = null;
                # pyinstaller = null;
                # editorconfig-checker = null;
                # pyqt5-stubs = null;
                # poetry-lock-package = null;
                # cibuildwheel = null;

                # mypy = super.mypy.overridePythonAttrs
                #   (old: {
                #     # preferWheels = true;
                #     # version = "0.991";
                #     # buildInputs = old.buildInputs ++ [ super.setuptools ];
                #     # src = pkgs.fetchzip
                #     #   {
                #     #     url = "https://files.pythonhosted.org/packages/0e/5c/fbe112ca73d4c6a9e65336f48099c60800514d8949b4129c093a84a28dc8/mypy-0.991.tar.gz";
                #     #     hash = "sha256-3cF5Ws3xrkruJ5D26lCwbTdW7MWH1oZfL68Kd92zxE0=";
                #     #   };
                #     # patches = [ ];
                #     # MYPY_USE_MYPYC = false;
                #     src = pkgs.fetchPypi {
                #       inherit (old) pname version;
                #       python = "py3";
                #       dist = "py3";
                #       sha256 = "sha256-ECHCQei24cpaR+TVJgEnSsB4qJhFz95mxtX3aYGf+h0=";
                #       format = "wheel";
                #     };
                #     format = "wheel";
                #     # pipBuildPhase = ''
                #     #   echo Foobar
                #     #   exit 1'';
                #     buildPhase = ''
                #       echo  build phase
                #       set -x
                #       ls -Rl
                #       pwd
                #     '';
                #   });

                # # The version of ruff used by parsec-cloud is too old for poetry2nix (version not listed)
                # ruff = super.ruff.overridePythonAttrs (old: {
                #   version = "0.1.12";
                # });

                # # Poetry2Nix don't have the version `39.0.1` of cryptography
                # cryptography = super.cryptography.overridePythonAttrs (old: {
                #   version = "39.0.2";
                # });

                async-exit-stack = super.async-exit-stack.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ super.setuptools ];
                });
                dukpy = super.dukpy.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ super.setuptools ];
                });
                maturin = super.maturin.overridePythonAttrs (old: {
                  nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.rustc pkgs.cargo pkgs.rustPlatform.cargoSetupHook ];
                  buildInputs = old.buildInputs ++ [ super.setuptools-rust ];
                  cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
                    inherit (old) src;
                    name = "${old.pname}-${old.version}";
                    hash = "sha256-LpXH0q4XhFAfXXdiww3TjRF6RQlLf6DKIpAhmp0j3os=";
                  };
                });
                trio-typing = super.trio-typing.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ super.setuptools ];
                });

                # hypothesis-trio = super.hypothesis-trio.overridePythonAttrs (old: {
                #   buildInputs = old.buildInputs ++ [ super.setuptools ];
                # });
                qtrio = super.qtrio.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ super.setuptools ];
                });
                toastedmarshmallow = super.toastedmarshmallow.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ super.setuptools ];
                });
                qts = super.qts.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ super.setuptools super.versioneer ];
                });
              });
          };
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
