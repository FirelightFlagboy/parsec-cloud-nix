{
  stdenvNoCC,
  fetchFromGitHub,
  version,
  commit_rev,
  commit_sha256,
  fetchpatch,
  lib,
}:

stdenvNoCC.mkDerivation {
  inherit version;
  pname = "parsec-cloud-src";
  src = fetchFromGitHub {
    owner = "Scille";
    repo = "parsec-cloud";
    rev = commit_rev;
    sha256 = commit_sha256;
  };
  patches = [
    ./patches/use-cdn-instead-of-vendored-xlsx.patch
    ./patches/use-libsodium-0.2-and-remove-patch-for-web-crates.patch
  ];
  installPhase = # shell
    ''
      cp -a . "$out"
    '';
}
