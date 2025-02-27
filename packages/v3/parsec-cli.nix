{
  makeRustPlatform,
  version,
  src,
  rust-toolchain,
  system,
  lib,
  pkg-config,
  openssl,
  sqlite,
  dbus,
  fuse3,
}:

(makeRustPlatform {
  cargo = rust-toolchain;
  rustc = rust-toolchain;
}).buildRustPackage
  {
    inherit version src;
    pname = "parsec-cli";

    cargoLock.lockFile = src + "/Cargo.lock";

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [
      openssl.dev
      sqlite.dev
      dbus.dev
      fuse3.dev
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
