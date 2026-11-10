{
  callPackage,
  dbus,
  fuse3,
  installShellFiles,
  lib,
  libgit2,
  makeRustPlatform,
  nix-update-script,
  openssl,
  rust-toolchain,
  source,
  system,
}:

let
  version = source.version;

  cliLibPaths = lib.makeLibraryPath [
    fuse3
    dbus
    openssl
  ];
  rustUtils = callPackage ./rust-utils.nix { inherit source; };
in
(makeRustPlatform {
  cargo = rust-toolchain;
  rustc = rust-toolchain;
}).buildRustPackage
  {
    inherit version;
    src = source;
    pname = "parsec-cli";

    inherit (rustUtils) cargoLock;

    nativeBuildInputs = rustUtils.nativeBuildInputs ++ [
      installShellFiles
    ];

    buildInputs = rustUtils.buildInputs ++ [
      libgit2.dev
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
