{ pkgs, src, version, ... }:

pkgs.buildNpmPackage {
  inherit version;
  pname = "parsec-native-build";

  src = "${src}/client";

  npmDepsHash = "sha256-afo/jMtauDTplm4PR6xRXhFTni4UGYETF2ZhapcA6I8=";

  makeCacheWritable = true; # Require for megashark-lib that build during a prepare hook.

  prePatch =
    let
      buildCmd = "vite build --mode=production";
    in
    ''
      set -e
      sed \
        -e '/postinstall/d' \
        -e 's;node ./scripts/vite_build_for_native.cjs;${buildCmd};' \
        -i package.json
    '';

  env =
    {
      PLATFORM = "native";
      CYPRESS_INSTALL_BINARY = "0";
    };

  npmBuildScript = "native:build";

  installPhase = ''
    mkdir -p $out
    cp -rva dist/{index.html,assets} $out
  '';

  meta = let inherit (pkgs.lib) majorMinor licenses platforms; in {
    homepage = "https://parsec.cloud/";
    description = "Parsec cloud native client build used for the electron app";
    branch = "releases/${majorMinor version}";
    license = [ licenses.bsl11 ];
    changelog = "https://github.com/Scille/parsec-cloud/tree/v${version}/HISTORY.rst";
    platforms = platforms.all;
  };
}
