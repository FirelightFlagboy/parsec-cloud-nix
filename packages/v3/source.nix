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
    rev = "e1bbc1cea713a496e15d15e80dbac23ab13f2537";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz | xargs nix hash convert --from nix32 --hash-algo sha256 `
    hash = "sha256-2jA6NA+mseIXPkj6JNKdq9V40v+MwWy5gjQOAEInK+I=";
  };
  patches = [
  ];
  installPhase = ''cp -a . "$out"'';
  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
