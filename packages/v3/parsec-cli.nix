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
  sqlite,
  src,
  system,
}:

let
  version = src.version;
in
(makeRustPlatform {
  cargo = rust-toolchain;
  rustc = rust-toolchain;
}).buildRustPackage
  {
    inherit version src;
    pname = "parsec-cli";

    cargoLock.lockFile = src + "/Cargo.lock";

    nativeBuildInputs = [
      pkg-config
      autoPatchelfHook
    ];
    buildInputs = [
      openssl
      sqlite
      dbus
      fuse3.dev
      libgcc
    ];

    buildAndTestSubdir = "cli";
    # Require running the `testbed` server to run the tests (+ access to `parsec-cli`).
    doCheck = false;

    meta =
      let
        inherit (lib) majorMinor licenses;
      in
      {
        homepage = "https://parsec.cloud/";
        description = "Parsec CLI";
        branch = "releases/${majorMinor version}";
        license = [ licenses.bsl11 ];
        changelog = "https://github.com/Scille/parsec-cloud/tree/v${version}/HISTORY.rst";
        platforms = [ system ];
      };
  }
