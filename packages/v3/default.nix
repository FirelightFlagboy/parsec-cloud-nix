{
  lib,
  newScope,
  rust-toolchain,
  system,
  isVersionPrerelease,
  poetry2nix,
}:

lib.makeScope newScope (self: {
  inherit rust-toolchain system poetry2nix;

  source = self.callPackage ./source.nix { };
  libparsec-node = self.callPackage ./libparsec-node.nix { };
  native-client-build = self.callPackage ./native-build.nix { inherit isVersionPrerelease; };
  client = self.callPackage ./electron-app.nix { };
  cli = self.callPackage ./parsec-cli.nix { };
  megashark-lib = self.callPackage ./megashark-lib.nix { };
  server = self.callPackage ./server.nix { };
})
