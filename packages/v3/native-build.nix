{
  buildNpmPackage,
  cairo,
  diffutils,
  isVersionPrerelease,
  jq,
  lib,
  makeSetupHook,
  nix-update-script,
  nodejs_24,
  pango,
  pixman,
  pkg-config,
  prefetch-npm-deps,
  source,
  megashark-lib,
}:

let
  version = source.version;
  nodejs = nodejs_24;
  isPrerelease = isVersionPrerelease source.version;
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

  src = "${source}/client";

  npmDepsHash = "sha256-H4CNKPf4xL690hh92fFqjzFCALVPDXd7vUuq1LAmp70=";

  makeCacheWritable = true; # Require for megashark-lib that build during a prepare hook.

  # Patch source to:
  # - remove call to `electron:install` script since this derivation is only for the native build of the client, the electron app is build in another derivation
  # - Directly call vite instead of `vite_build_for_native.cjs`, it's only a wrapper around `npm`
  prePatch =
    let
      buildCmd = "vite build --mode=${if isPrerelease then "release-candidate" else "production"}";
    in
    ''
      set -e
      sed \
        -e 's/npm run electron:install && //' \
        -e 's;node ./scripts/vite_build_for_native.cjs;${buildCmd};' \
        -i package.json
    '';

  # Need to patch `megashark-lib` dep as it is missing transpiled files
  preBuild = ''
    ln -sv ${megashark-lib}/lib/node_modules/megashark-lib/dist node_modules/megashark-lib/dist
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
      "--url=${source.src.url}"
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
