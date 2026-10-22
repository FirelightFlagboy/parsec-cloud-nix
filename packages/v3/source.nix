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
    rev = "e5c154d46eed8bd7ef37a97f3a9db90ba1d63bdc";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz | xargs nix hash convert --from nix32 --hash-algo sha256 `
    hash = "sha256-kenXCcNiYwhnNznvN7rJ8ueHkLIh40cxdcltRCG7Z5Y=";
  };
  patches = [
  ];
  installPhase = ''cp -a . "$out"'';
  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
