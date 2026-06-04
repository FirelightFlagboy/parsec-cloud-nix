{
  fetchFromGitHub,
  buildNpmPackage,
  lib,
  nix-update-script,
  source,
}:

buildNpmPackage rec {
  pname = "megashark-lib";
  version = "f43d5eb726071b7aa29293e3a62d315eb7ef078f";

  src = fetchFromGitHub {
    owner = "Scille";
    repo = "megashark-lib";
    rev = version;
    hash = "sha256-cra+UG3ywg0iV/ZNTMAeuYdjm3apk7Jh8JhEXmwgWCI=";
  };
  npmDepsHash = "sha256-GtxtVtAkj164CZD/GxfN2CWGtdE6f5HHl79a6c30GMA=";

  meta = {
    homepage = "https://github.com/Scille/megashark-lib";
    description = "Generic UI library based on Ionic";
    branch = "master";
    license = [ lib.licenses.bsl11 ];
    platforms = lib.platforms.all;
  };

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=${source.passthru.megashark-lib-rev}"
    ];
  };
}
