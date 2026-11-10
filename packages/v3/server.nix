{
  python314,
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
  python = python314;
  pythonVersionNoDot = builtins.replaceStrings [ "." ] [ "" ] python.pythonVersion;

  systemToPlatform = {
    "x86_64-linux" = "manylinux_2_28_x86_64";
  };

  hashes = {
    "314-x86_64-linux" = "sha256-bgXpYQXZqhstQT4Kg5d5dB03wKOfhPZ8MEEvwcMjDNE=";
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
