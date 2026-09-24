{
  fetchFromGitHub,
  stdenvNoCC,
  nix-update-script,
}:

stdenvNoCC.mkDerivation rec {
  pname = "parsec-cloud-src";
  version = "3.10.0-rc.1";
  src = fetchFromGitHub {
    owner = "Scille";
    repo = "parsec-cloud";
    tag = "v${version}";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz`
    hash = "sha256-95f+/UCLaRyeM9bg74sPfXKQHFIxzvjjfSxFEWSpfxg=";
  };
  patches = [
  ];
  installPhase = ''cp -a . "$out"'';
  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
