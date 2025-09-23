{
  makeRustPlatform,
  version,
  src,
  rust-toolchain,
  system,
  openssl,
  sqlite,
  fuse3,
  autoPatchelfHook,
  dbus,
  pkg-config,
  libgcc,
  lib,
}:

(makeRustPlatform {
  cargo = rust-toolchain;
  rustc = rust-toolchain;
}).buildRustPackage
  {
    inherit version src;
    name = "libparsec-node-module";
    outputs = [
      "out"
      "typing"
    ];

    # Crate to build
    buildAndTestSubdir = "bindings/electron";
    cargoBuildFeatures = [ ];

    cargoLock.lockFile = "${src}/Cargo.lock";

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

    nativeBuildInputs = [
      pkg-config
      autoPatchelfHook
    ];
    buildInputs = [
      openssl
      sqlite
      fuse3.dev
      dbus
      libgcc
    ];

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
