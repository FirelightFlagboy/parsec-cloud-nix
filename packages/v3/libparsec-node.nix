{
  callPackage,
  lib,
  makeRustPlatform,
  nix-update-script,
  rust-toolchain,
  source,
  system,
}:

let
  rustUtils = callPackage ./rust-utils.nix { inherit source; };
in
(makeRustPlatform {
  cargo = rust-toolchain;
  rustc = rust-toolchain;
}).buildRustPackage
  rec {
    src = source;
    version = source.version;
    name = "libparsec-node-module";
    outputs = [
      "out"
      "typing"
    ];

    inherit (rustUtils) cargoLock nativeBuildInputs buildInputs;

    # Crate to build
    buildAndTestSubdir = "bindings/electron";
    cargoBuildFeatures = [ ];

    doCheck = false;

    # Copy file after fixup.
    postFixup =
      let
        artifact_name = "liblibparsec_bindings_electron.so";
        typescript_def_path = "bindings/electron/src/index.d.ts";
      in
      ''
        ln -s $out/lib/${artifact_name} $out/libparsec.node
        install -v --directory $typing
        install -v -m 444 -p $src/${typescript_def_path} $typing/libparsec.d.ts
      '';

    passthru.updateScript = nix-update-script {
      extraArgs = [
        "--flake"
        "--url=${source.src.url}"
        "--no-src"
      ];
    };

    meta =
      let
        inherit (lib) majorMinor licenses;
      in
      {
        homepage = "https://parsec.cloud/";
        description = "Parsec library for Node.js";
        branch = "releases/${majorMinor version}";
        license = [ licenses.bsl11 ];
        changelog = "https://github.com/Scille/parsec-cloud/tree/v${version}/HISTORY.rst";
        platforms = [ system ];
      };
  }
