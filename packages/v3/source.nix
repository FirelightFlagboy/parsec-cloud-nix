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
    rev = "01bb7ac383597b95cabbed5370f6445070b12c27";
    # `nix-prefetch-url --unpack https://github.com/${owner}/${repo}/archive/${commit_rev}.tar.gz | xargs nix hash convert --from nix32 --hash-algo sha256 `
    hash = "sha256-dQ6JndXQqfxS5eRuqfeGREJ0oIVwaQaJkFmePVg+8t0=";
  };
  patches = [
  ];
  installPhase = ''cp -a . "$out"'';
  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
