{
  fetchFromGitHub,
  stdenvNoCC,
  nix-update-script,
}:

stdenvNoCC.mkDerivation rec {
  pname = "parsec-cloud-src";
  version = "3.11.0-rc.3+dev";
  src = fetchFromGitHub {
    owner = "Scille";
    repo = "parsec-cloud";
    # tag = "v${version}";
    rev = "42e2eeb185f89e015e37d2ae83d7f787b4dd5557";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz | xargs nix hash convert --from nix32 --hash-algo sha256 `
    hash = "sha256-HQWZM7TTaLSJSpGFnfDL6qT5OHhZD0RPrleoxL6NphM=";
  };
  patches = [
  ];
  installPhase = ''cp -a . "$out"'';
  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
