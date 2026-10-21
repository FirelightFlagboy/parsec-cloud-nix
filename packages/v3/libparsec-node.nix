{
  autoPatchelfHook,
  dbus,
  fuse3,
  lib,
  libgcc,
  makeRustPlatform,
  openssl,
  pkg-config,
  rust-toolchain,
  source,
  sqlite,
  system,
  nix-update-script,
}:

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

    # Crate to build
    buildAndTestSubdir = "bindings/electron";
    cargoBuildFeatures = [ ];

    cargoLock = {
      lockFile = "${source}/Cargo.lock";
      outputHashes = {
        "fuser-0.18.1" = "sha256-Aei/daoV3th+uAsoICkToXORcWZBZoX3st8wE2rtyig=";
        "scwsapi-0.8.1" = "sha256-0bblcz81lM5booIH2I17SHJEWIY2K/Pgk1hUOgpebVA=";
      };
    };

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
