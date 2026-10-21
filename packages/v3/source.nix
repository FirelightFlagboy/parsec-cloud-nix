{
  fetchFromGitHub,
  stdenvNoCC,
  nix-update-script,
}:

stdenvNoCC.mkDerivation rec {
  pname = "parsec-cloud-src";
  version = "3.11.0-rc.2";
  src = fetchFromGitHub {
    owner = "Scille";
    repo = "parsec-cloud";
    tag = "v${version}";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz`
    hash = "sha256-7jeWY6Gs5rBYJdXLYB52/g30p4RxhObTbsrXRH33tQo=";
  };
  patches = [
  ];
  installPhase = ''cp -a . "$out"'';
  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
