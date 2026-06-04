{
  autoPatchelfHook,
  dbus,
  fuse3,
  lib,
  libgcc,
  makeRustPlatform,
  nix-update-script,
  openssl,
  pkg-config,
  rust-toolchain,
  sqlite,
  source,
  system,
}:

let
  version = source.version;
in
(makeRustPlatform {
  cargo = rust-toolchain;
  rustc = rust-toolchain;
}).buildRustPackage
  {
    inherit version;
    src = source;
    pname = "parsec-cli";

    cargoLock = {
      lockFile = "${source}/Cargo.lock";
      outputHashes = {
        "scwsapi-0.8.0" = "sha256-tPn9rClBAJRz0XRNrcLLP/kkD++m3t+h5ovFL3cxDrY=";
      };
    };

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
        description = "Parsec CLI";
        branch = "releases/${majorMinor version}";
        license = [ licenses.bsl11 ];
        changelog = "https://github.com/Scille/parsec-cloud/tree/v${version}/HISTORY.rst";
        platforms = [ system ];
      };
  }
