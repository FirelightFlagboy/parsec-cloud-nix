{
  lib,
  newScope,
  rust-toolchain,
  system,
  isVersionPrerelease,
}:

lib.makeScope newScope (self: {
  version = "3.7.0";
  # Currently parsec-cloud only provide a nightly release for v3 which change each day.
  # So fixing the commit_rev to stay on the same version.
  commit_rev = "5ca6effd91fb8a3ca4d85fac0802f41767346662";
  # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz`
  commit_sha256 = "1kjcx0zh34xaw5bdya06zw01gpf7lfrc0v1xzh6ijqp9xgqwvsr6";

  inherit rust-toolchain system;
  isPrerelease = isVersionPrerelease self.version;

  src = self.callPackage ./source.nix { };
  libparsec-node = self.callPackage ./libparsec-node.nix { };
  native-client-build = self.callPackage ./native-build.nix { };
  capacitor-electron = self.callPackage ./capacitor-electron.nix { };
  client = self.callPackage ./electron-app.nix { };
  cli = self.callPackage ./parsec-cli.nix { };
})
