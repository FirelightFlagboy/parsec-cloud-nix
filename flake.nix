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

            nativeBuildInputs = [
              pkgs.qt5.wrapQtAppsHook

              # Required to build rust binding
              pkgs.patchelf
              pkgs.maturin
              pkgs.cargo
              pkgs.rustc
              pkgs.rustPlatform.cargoSetupHook
              pkgs.qt5.qttools

              # Needed to build openssl-src
              pkgs.buildPackages.perl
            ];

            propagatedBuildInputs = [ pkgs.qt5.qtbase pkgs.qt5.qtwayland ];

            cargoDeps = pkgs.rustPlatform.importCargoLock {
              lockFile = "${parsec-cloud-src-patched}/Cargo.lock";
            };

            makeWrapperArgs = with pkgs; [
              "--set FUSE_LIBRARY_PATH ${fuse}/lib/libfuse.so.${fuse.version}"
              "--prefix LD_LIBRARY_PATH : ${pkgs.qt5.qtbase}/lib"
              "--prefix LD_LIBRARY_PATH : ${pkgs.qt5.qtwayland}/lib"
              # TODO: find a way to make this work join plugin of qtbase + qtwayland
              # "--set QT_QPA_PLATFORM_PLUGIN_PATH '${qt5.qtbase}/lib/qt-${qt5.qtbase.version}/plugins/platforms ${qt5.qtwayland}/lib'"
              # "--set QT_QPA_PLATFORM_PLUGIN_PATH ${qt5.qtbase}/lib/qt-${qt5.qtbase.version}/plugins/platforms"
              # "--set QT_QPA_PLATFORM_PLUGIN_PATH ${qt5.qtwayland}/lib"
              # "--set QT_QPA_PLATFORM_PLUGIN_PATH ${qt5.qtwayland.bin}/lib/qt-${qt5.qtwayland.version}/plugins/platforms"
            ];

            overrides = poetry2nix.overrides.withDefaults
              (self: super: {
                pywin32 = null;
                winfspy = null;

                # pyqt5-sip = pkgs.python39Packages.pyqt5_sip;

                patchelf = super.patchelf.overridePythonAttrs (old: {
                  nativeBuildInputs = old.nativeBuildInputs ++ [
                    pkgs.buildPackages.pkg-config
                    pkgs.buildPackages.cmake
                    pkgs.buildPackages.autoconf
                    pkgs.buildPackages.automake
                  ];
                  buildInputs = old.buildInputs ++ [
                    super.setuptools
                    super.setuptools-scm
                    super.scikit-build
                  ];
                  buildPhase = ''
                    ${super.python}/bin/python3 -m pip wheel --verbose --no-index --no-deps --no-clean --no-build-isolation --wheel-dir dist ..
                  '';
                });

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

                qtrio = super.qtrio.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ super.setuptools ];

                  extras = [ "pyqt5" ];
                });
                toastedmarshmallow = super.toastedmarshmallow.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ super.setuptools ];
                });
                qts = super.qts.overridePythonAttrs (old: {
                  buildInputs = old.buildInputs ++ [ super.setuptools super.versioneer ];

                  extras = [ "pyqt5" ];
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
