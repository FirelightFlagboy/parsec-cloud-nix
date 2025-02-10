{ pkgs, version, src, rust-toolchain, system, ... }:

(pkgs.makeRustPlatform {
  cargo = rust-toolchain;
  rustc = rust-toolchain;
}).buildRustPackage {
  inherit version src;
  pname = "parsec-cli";

  cargoLock.lockFile = src + "/Cargo.lock";

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [
    pkgs.openssl.dev
    pkgs.sqlite.dev
    pkgs.dbus.dev
    pkgs.fuse3.dev
  ];

  # Require running the `testbed` server to run the tests (+ access to `parsec-cli`).
  doCheck = false;

  meta = let inherit (pkgs.lib) majorMinor licenses; in {
    homepage = "https://parsec.cloud/";
    description = "Parsec CLI";
    branch = "releases/${majorMinor version}";
    license = [ licenses.bsl11 ];
    changelog = "https://github.com/Scille/parsec-cloud/tree/v${version}/HISTORY.rst";
    platforms = [ system ];
  };
}
