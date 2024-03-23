{ poetry2nix, parsec-cloud-src, pkgs, system, ... }:

poetry2nix.mkPoetryApplication
{
  projectDir = parsec-cloud-src;
  extras = [ "core" ];
  python = pkgs.python39;

  nativeBuildInputs = [
    pkgs.qt5.wrapQtAppsHook
    pkgs.wrapGAppsHook

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

  propagatedBuildInputs = [ pkgs.qt5.qtbase pkgs.qt5.qtwayland pkgs.gtk3 ];

  cargoDeps = pkgs.rustPlatform.importCargoLock {
    lockFile = "${parsec-cloud-src}/Cargo.lock";
  };

  # We do a single wrap operation for all the dependencies
  dontWrapQtApps = true;
  dontWrapGApps = true;

  # `poetry2nix` already do a wrapping operation for us.
  # We need to add aditional arguments for the application to work with QT, Fuse and Dconf.
  makeWrapperArgs = with pkgs; [
    "\${qtWrapperArgs[@]}"
    "\${gappsWrapperArgs[@]}"
    "--set FUSE_LIBRARY_PATH ${fuse}/lib/libfuse.so.${fuse.version}"
  ];

  overrides = poetry2nix.overrides.withDefaults
    (self: super: {
      pywin32 = null;
      winfspy = null;

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
        version = "0.15.1";
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
      toastedmarshmallow = super.toastedmarshmallow.overridePythonAttrs (old: {
        buildInputs = old.buildInputs ++ [ super.setuptools ];
      });

      pyqt5-stubs = super.pyqt5-stubs.overridePythonAttrs (old: {
        buildInputs = old.buildInputs ++ [ super.setuptools ];
      });
      qtrio = super.qtrio.overridePythonAttrs (old: {
        buildInputs = old.buildInputs ++ [ super.setuptools ];

        extras = [ "pyqt5" ];
      });

      qts = super.qts.overridePythonAttrs (old: {
        buildInputs = old.buildInputs ++ [ super.setuptools super.versioneer ];

        extras = [ "pyqt5" ];
      });
    });

  meta = parsec-cloud-src.meta // {
    platforms = [ system ];
  };

}
