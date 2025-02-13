{
  pkgs,
  src,
  version,
  isPrerelease,
  ...
}:

let
  patchedSrc = pkgs.stdenvNoCC.mkDerivation {
    inherit version src;
    pname = "parsec-cloud-client-src";
    patches = [
      ./patches/use-cdn-instead-of-vendored-xlsx.patch
    ];
    patchFlags = "--strip=1 --verbose";
    installPhase = # shell
      ''
        mkdir -p "$out"
        cp -ra client "$out"
      '';
  };
  inherit (pkgs) buildNpmPackage;
  nodejs = pkgs.nodejs_20;
  # TODO: Should be fixed once https://github.com/NixOS/nixpkgs/pull/381409 is merged.
  npmConfigHook = pkgs.makeSetupHook {
    name = "npm-config-hook";
    substitutions = {
      nodeSrc = nodejs;
      nodeGyp = "${nodejs}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js";

      # Specify `diff`, `jq`, and `prefetch-npm-deps` by abspath to ensure that the user's build
      # inputs do not cause us to find the wrong binaries.
      diff = "${pkgs.diffutils}/bin/diff";
      jq = "${pkgs.jq}/bin/jq";
      prefetchNpmDeps = "${pkgs.prefetch-npm-deps}/bin/prefetch-npm-deps";

      nodeVersion = nodejs.version;
      nodeVersionMajor = pkgs.lib.versions.major nodejs.version;
    };
  } ./npm-config-hook.sh;
in
buildNpmPackage {
  inherit version;
  pname = "parsec-native-build";

  src = "${patchedSrc}/client";

  npmDepsHash = "sha256-ih6Fa3A3aoYEsbJf403xvNqgpQzFeBniuUaKHFYr8xA=";

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
    pkgs.pkg-config
  ];
  nodejs = nodejs;
  buildInputs = [
    # Dependencies for canvas dependency
    pkgs.pixman
    pkgs.cairo.dev
    pkgs.pango.dev
    # End of dependencies for canvas dependency
  ];
  npmBuildScript = "native:build";

  installPhase = ''
    mkdir -p $out
    cp -rva dist/{index.html,assets} $out
  '';

  meta =
    let
      inherit (pkgs.lib) majorMinor licenses platforms;
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
