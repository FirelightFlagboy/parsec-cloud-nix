{
  fetchFromGitHub,
  stdenvNoCC,
  nix-update-script,
  lib,
}:

stdenvNoCC.mkDerivation rec {
  pname = "parsec-cloud-src";
  version = "3.9.0";
  src = fetchFromGitHub {
    owner = "Scille";
    repo = "parsec-cloud";
    tag = "v${version}";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz`
    hash = "sha256-0SmdUiY8nLnBratNXlcEMvZCnRk7x+jL0RQfQS52OuE=";
  };
  patches = [
  ];
  installPhase = ''cp -a . "$out"'';
  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
  passthru.megashark-lib-rev = lib.pipe "${src}/client/package-lock.json" [
    builtins.readFile
    builtins.fromJSON
    (lock: lock.packages."node_modules/megashark-lib".resolved)
    (url: lib.splitString "\#" url)
    builtins.tail
    builtins.head
  ];
}
