{
  buildNpmPackage,
  cairo,
  diffutils,
  isVersionPrerelease,
  jq,
  lib,
  makeSetupHook,
  nix-update-script,
  nodejs_20,
  pango,
  pixman,
  pkg-config,
  prefetch-npm-deps,
  src,
}:

let
  version = src.version;
  nodejs = nodejs_20;
  isPrerelease = isVersionPrerelease src.version;
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

  npmDepsHash = "sha256-q9D/PT9es/G9KMqx0/2y/c51KBOPOAnkb1R7R0TsPDg=";

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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--url=${src.src.url}"
      "--no-src" # No `src` to update, only `npmDepsHash`
    ];
  };

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
