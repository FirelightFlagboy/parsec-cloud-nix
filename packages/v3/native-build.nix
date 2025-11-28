{
  stdenvNoCC,
  src,
  version,
  isPrerelease,
  buildNpmPackage,
  nodejs_20,
  makeSetupHook,
  diffutils,
  jq,
  prefetch-npm-deps,
  lib,
  pkg-config,
  pixman,
  cairo,
  pango,
}:

let
  nodejs = nodejs_20;
  # TODO: Should be fixed once https://github.com/NixOS/nixpkgs/pull/381409 is merged.
  npmConfigHook = makeSetupHook {
    name = "npm-config-hook";
    substitutions = {
      nodeSrc = nodejs;
      nodeGyp = "${nodejs}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js";

      # Specify `diff`, `jq`, and `prefetch-npm-deps` by abspath to ensure that the user's build
      # inputs do not cause us to find the wrong binaries.
      diff = "${diffutils}/bin/diff";
      jq = "${jq}/bin/jq";
      prefetchNpmDeps = "${prefetch-npm-deps}/bin/prefetch-npm-deps";

      nodeVersion = nodejs.version;
      nodeVersionMajor = lib.versions.major nodejs.version;
    };
  } ./npm-config-hook.sh;
in
buildNpmPackage {
  inherit version;
  pname = "parsec-native-build";

  src = "${src}/client";

  npmDepsHash = "sha256-Ljm5EU2FH4cf8YRULvR9w/dcWktlYM1UQWppxl8own4=";

  makeCacheWritable = true; # Require for megashark-lib that build during a prepare hook.

  prePatch =
    let
      buildCmd = "vite build --mode=${if isPrerelease then "release-candidate" else "production"}";
    in
    ''
      set -e
      sed \
        -e '/postinstall/d' \
        -e 's;node ./scripts/vite_build_for_native.cjs;${buildCmd};' \
        -i package.json
    '';
  npmConfigHook = npmConfigHook;

  env = {
    PLATFORM = "native";
    CYPRESS_INSTALL_BINARY = "0";
  };
  nativeBuildInputs = [
    pkg-config
  ];
  nodejs = nodejs;
  buildInputs = [
    # Dependencies for canvas dependency
    pixman
    cairo.dev
    pango.dev
    # End of dependencies for canvas dependency
  ];
  npmBuildScript = "native:build";

  installPhase = ''
    mkdir -p $out
    cp -rva dist/{index.html,assets} $out
  '';

  meta =
    let
      inherit (lib) majorMinor licenses platforms;
    in
    {
      homepage = "https://parsec.cloud/";
      description = "Parsec cloud native client build used for the electron app";
      branch = "releases/${majorMinor version}";
      license = [ licenses.bsl11 ];
      changelog = "https://github.com/Scille/parsec-cloud/tree/v${version}/HISTORY.rst";
      platforms = platforms.all;
    };
}
