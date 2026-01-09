{
  fetchFromGitHub,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "parsec-cloud-src";
  version = "3.7.0";
  src = fetchFromGitHub {
    owner = "Scille";
    repo = "parsec-cloud";
    tag = "v${version}";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz`
    sha256 = "1kjcx0zh34xaw5bdya06zw01gpf7lfrc0v1xzh6ijqp9xgqwvsr6";
  };
  patches = [
    ./patches/use-cdn-instead-of-vendored-xlsx.patch
  ];
  installPhase = ''cp -a . "$out"'';
}
