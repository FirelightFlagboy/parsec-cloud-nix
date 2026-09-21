{
  fetchFromGitHub,
  stdenvNoCC,
  nix-update-script,
}:

stdenvNoCC.mkDerivation rec {
  pname = "parsec-cloud-src";
  version = "3.10.0-rc.0";
  src = fetchFromGitHub {
    owner = "Scille";
    repo = "parsec-cloud";
    tag = "v${version}";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz`
    hash = "sha256-C5gr2nkls5CZ2fp/pSaa0NrM+C/bdQhyDJHBxYHpSLc=";
  };
  patches = [
  ];
  installPhase = ''cp -a . "$out"'';
  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
