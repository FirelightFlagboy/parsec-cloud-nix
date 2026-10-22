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
    rev = "cbbe28f56b7a6d08af46c96c8afd9853e8dec042";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz | xargs nix hash convert --from nix32 --hash-algo sha256 `
    hash = "sha256-BAVCzf1p5sy5NUkuDFJGdwy7iy5z626RYI1wYVO440M=";
  };
  patches = [
  ];
  installPhase = ''cp -a . "$out"'';
  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
