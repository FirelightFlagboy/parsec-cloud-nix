{
  lib,
  newScope,
  rust-toolchain,
  system,
  isVersionPrerelease,
}:

lib.makeScope newScope (self: {
  inherit rust-toolchain system;

  src = self.callPackage ./source.nix { };
  libparsec-node = self.callPackage ./libparsec-node.nix { };
  native-client-build = self.callPackage ./native-build.nix { inherit isVersionPrerelease; };
  capacitor-electron = self.callPackage ./capacitor-electron.nix { };
  client = self.callPackage ./electron-app.nix { };
  cli = self.callPackage ./parsec-cli.nix { };
})
