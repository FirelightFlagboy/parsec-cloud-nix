{
  commit_rev,
  commit_sha256,
  fetchFromGitHub,
  stdenvNoCC,
  version,
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
  ];
  installPhase = ''cp -a . "$out"'';
}
