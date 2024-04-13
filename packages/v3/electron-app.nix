{ pkgs, src, client-build, libparsec, ... }:

let
  pkgVersion = libparsec.version;
  pkgMajor = pkgs.lib.versions.major pkgVersion;
in
pkgs.buildNpmPackage {
  pname = "parsec-cloud";
  version = pkgVersion;
  outputs = [ "out" "icon" ];

  src = "${src}/client/electron";

  npmDepsHash = "sha256-kOGJtJkwkU8/N1iVW23OaRcEdVxn0cLKodRufRbrV4g=";

  configurePhase = ''
    mkdir -pv build/{,generated-ts/}src app
    install -v -p -m 444 ${libparsec.typing}/libparsec.d.ts build/generated-ts/src/libparsec.d.ts
    install -v -p -m 555 ${libparsec}/libparsec.node build/src/libparsec.node
    cp -ra ${client-build}/. app
  '';

  # prevent electron download from electron in package.json
  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  };

  buildPhase = ''
    npx tsc
    node package.js --mode prod --platform linux --export > electron-builder-config.json
    npm exec electron-builder -- \
      --linux \
      --dir \
      --config=electron-builder-config.json \
      --config.electronDist=${pkgs.electron_28}/libexec/electron \
      --config.electronVersion=${pkgs.electron_28.version}
  '';

  # Inspired by https://github.com/NixOS/nixpkgs/blob/af105fd3758230351db538ade56e862ac947f849/pkgs/development/tools/electron/wrapper.nix
  installPhase = ''
    mkdir -pv $out/bin
    cp -r dist/linux-unpacked $out/libexec

    gappsWrapperArgsHook
    makeBinaryWrapper $out/libexec/parsec-v${pkgMajor} $out/bin/parsec \
      "''${gappsWrapperArgs[@]}" \
      --set CHROME_DEVEL_SANDBOX $out/libexec/chrome-sandbox

    cp -rva assets/icon.png $icon
  '';

  nativeBuildInputs = [ pkgs.wrapGAppsHook pkgs.makeWrapper pkgs.patchelf ];
  dontWrapGApps = true;

  meta = libparsec.meta // {
    mainProgram = "parsec";
    description = "Open source Dropbox-like file sharing with full client encryption !";
  };
}
