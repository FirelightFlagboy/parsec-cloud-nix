{
  fetchFromGitHub,
  buildNpmPackage,
  lib,
  nix-update-script,
  source,
}:

buildNpmPackage rec {
  pname = "megashark-lib";
  version = "0a3fcd5c02e296c9ff8238fe1c222034decb7ad4";

  src = fetchFromGitHub {
    owner = "Scille";
    repo = "megashark-lib";
    rev = version;
    hash = "sha256-g1VsX0iW1ch/+FgVCwsxwRU7xygltiSGKk3fkUGTPi0=";
  };
  npmDepsHash = "sha256-tBEAiyHXjMt0Zj2DegGs8udHrlHRdO1J1jfBrxpiq1I=";

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
