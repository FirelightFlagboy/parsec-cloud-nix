{
  fetchFromGitHub,
  buildNpmPackage,
}:

buildNpmPackage {
  pname = "capacitor-community/electron";
  version = "5.0.2";

  src = fetchFromGitHub {
    owner = "Scille";
    repo = "capacitor-electron";
    rev = "415b25cb411ac3957a3d5d25d2a68e5f350161cb";
    sha256 = "sha256-CdON+bWmVeVHVUjBcq3dnWPQL3YB2dGR2Of1R4lvlDA=";
  };

  npmDepsHash = "sha256-IFlElWNT5SWid08kYiFUZ3eox7lfpbvAZrHPvjSiWRE=";

  # prevent electron download from electron in package.json
  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  };
}
