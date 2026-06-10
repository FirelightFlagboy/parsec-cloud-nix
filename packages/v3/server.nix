{
  python312,
  fetchPypi,
  source,
  libparsec-node,
  lib,
  autoPatchelfHook,
  stdenv,
  ...
}:

# /!\ This is a best effort packaging

# Inspired by:
# https://github.com/NixOS/nixpkgs/blob/46388eeeb636df30c1fb2c866cef95bdc162272e/pkgs/development/python-modules/tensorstore/default.nix#L41
let
  python = python312.override {
    packageOverrides =
      self: super:
      let
        mkDisabledCheck =
          name:
          super.${name}.overridePythonAttrs (old: {
            doCheck = false;
          });
      in
      (lib.attrsets.genAttrs [
        # Skip test since it depends more recent trio version than provided by the overwritten anyio
        "fastapi"
        "httpcore"
        "httpx"
        "oslo-i18n"
      ] mkDisabledCheck)
      // {
        anyio = buildPythonPackage rec {
          pname = "anyio";
          version = "3.7.1";
          format = "wheel";

          src = fetchPypi {
            inherit pname version;
            format = "wheel";

            dist = "py3";
            python = "py3";
            hash = "sha256-kd7kFuVw6SxkBBvRi5ANHW+njf9wSHac5axd2tAE+7U=";
          };

          optional-dependencies = {
            trio = [ self.trio ];
          };

          dependencies = [
            self.idna
            self.sniffio
          ];

          doCheck = false;
        };

        starlette = super.starlette.overridePythonAttrs (old: {
          # Skip test since it depends more recent trio version than provided by the overwritten anyio
          doCheck = false;

          dependencies = old.dependencies ++ [
            self.typing-extensions
          ];
        });

        # Need `uvicorn<0.36,>=0.35.0`
        uvicorn = buildPythonPackage rec {
          pname = "uvicorn";
          version = "0.35.0";
          format = "wheel";

          src = fetchPypi {
            inherit pname version;
            format = "wheel";

            dist = "py3";
            python = "py3";
            hash = "sha256-GXU1IWsl/5t4Ximgt5GZ9VIiGT1H+CCBbn2nUem8jUo=";
          };

          dependencies = [
            python.pkgs.click
            python.pkgs.h11
          ];
        };

        # Need `asyncpg<0.30,>=0.29.0`
        asyncpg = buildPythonPackage rec {
          pname = "asyncpg";
          version = "0.29.0";
          format = "wheel";

          src =
            let
              systemToPlatform = {
                "x86_64-linux" = "manylinux_2_17_x86_64.manylinux2014_x86_64";
              };
            in
            fetchPypi {
              inherit pname version;
              format = "wheel";

              dist = "cp${pythonVersionNoDot}";
              python = "cp${pythonVersionNoDot}";
              abi = "cp${pythonVersionNoDot}";
              platform = systemToPlatform.${stdenv.system} or (throw "unsupported system for asyncpg");

              hash = "sha256-VIWLwltJ0RFBeNZaiOSK1QyytvPkdcqg8MCS1fUnwQY=";
            };

        };

        # Need `pbr<7,>=6.1.1`
        pbr = buildPythonPackage rec {
          pname = "pbr";
          version = "6.1.1";
          format = "wheel";

          src = fetchPypi {
            inherit pname version;
            format = "wheel";
            hash = "sha256-ONTa6l2fpjs/YmExudNJR/0Mi+mwWiknaHBYAFCiWnY=";
          };

          dependencies = [
            self.setuptools
            self.typing-extensions
            self.distutils
          ];
        };
      };
  };
  pythonVersionNoDot = builtins.replaceStrings [ "." ] [ "" ] python.pythonVersion;

  systemToPlatform = {
    "x86_64-linux" = "manylinux_2_28_x86_64";
  };

  hashes = {
    "312-x86_64-linux" = "sha256-hGeLUmO6Sftp9+A7CDp8MByksRGlPafhS6NatkXzW6Y=";
  };

  inherit (python.pkgs) buildPythonPackage;
in
python.pkgs.buildPythonPackage rec {
  pname = "parsec-cloud";
  version = source.version;
  format = "wheel";

  src = fetchPypi {
    pname = "parsec_cloud";
    inherit version;
    format = "wheel";

    hash =
      hashes."${pythonVersionNoDot}-${stdenv.system}"
        or (throw "unsupported system/python version combination");
    # https://pypi.org/project/parsec-cloud/#files
    dist = "cp${pythonVersionNoDot}";
    python = "cp${pythonVersionNoDot}";
    abi = "cp${pythonVersionNoDot}";
    platform = systemToPlatform.${stdenv.system} or (throw "unsupported system");
  };

  nativeBuildInputs = (lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ]);

  dependencies = builtins.attrValues {
    inherit (python.pkgs)
      anyio
      asyncpg
      boto3
      botocore
      click
      cryptography
      fastapi
      httpx
      jinja2
      pbr
      pydantic
      pydantic-core
      python-swiftclient
      sentry-sdk
      starlette
      structlog
      uvicorn
      ;
  };

  meta = {
    inherit (libparsec-node.meta)
      homepage
      branch
      license
      changelog
      platforms
      ;
    description = "The parsec-cloud's server";
  };
}
