{
  autoPatchelfHook,
  dbus,
  fuse3,
  installShellFiles,
  lib,
  libgcc,
  makeRustPlatform,
  nix-update-script,
  openssl,
  pkg-config,
  rust-toolchain,
  source,
  sqlite,
  system,
}:

let
  version = source.version;

  cliLibPaths = lib.makeLibraryPath [
    fuse3
    dbus
    openssl
  ];
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
        "scwsapi-0.8.1" = "sha256-0bblcz81lM5booIH2I17SHJEWIY2K/Pgk1hUOgpebVA=";
      };
    };

    nativeBuildInputs = [
      pkg-config
      autoPatchelfHook
      installShellFiles
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

    postInstall = ''
      mkdir -p generated-manpages
      LD_LIBRARY_PATH=${cliLibPaths} $out/bin/parsec-cli man-page --mode=separate generated-manpages
      installManPage generated-manpages/*.?

      mkdir -p completions
      for shell in bash fish zsh; do
        LD_LIBRARY_PATH=${cliLibPaths} $out/bin/parsec-cli auto-complete $shell > completions/parsec-cli.$shell
      done
      installShellCompletion --cmd parsec-cli \
        --bash completions/parsec-cli.bash \
        --fish completions/parsec-cli.fish \
        --zsh completions/parsec-cli.zsh
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
        description = "Parsec CLI";
        branch = "releases/${majorMinor version}";
        license = [ licenses.bsl11 ];
        changelog = "https://github.com/Scille/parsec-cloud/tree/v${version}/HISTORY.rst";
        platforms = [ system ];
      };
  }
