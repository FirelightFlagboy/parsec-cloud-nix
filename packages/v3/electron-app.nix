{ pkgs, src, client-build, libparsec, ... }:

let
  pkgVersion = libparsec.version;
  pkgMajor = pkgs.lib.versions.major pkgVersion;
  binName = "parsec";
in
pkgs.buildNpmPackage {
  pname = "parsec-cloud";
  version = pkgVersion;
  outputs = [ "out" "icon" ];

  src = "${src}/client/electron";

  npmDepsHash = "sha256-XnKtqtfIud88DPhVtfJOQ6Ephfb6t4XIBjg3Po/njmI=";

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
      --config.electronDist=${pkgs.electron_30}/libexec/electron \
      --config.electronVersion=${pkgs.electron_30.version}
  '';

  # Inspired by https://github.com/NixOS/nixpkgs/blob/af105fd3758230351db538ade56e862ac947f849/pkgs/development/tools/electron/wrapper.nix
  installPhase = ''
    mkdir -pv $out/bin
    cp -r dist/linux-unpacked $out/libexec

    gappsWrapperArgsHook
    makeWrapper $out/libexec/${binName} $out/bin/${binName} \
      "''${gappsWrapperArgs[@]}" \
      --set CHROME_DEVEL_SANDBOX $out/libexec/chrome-sandbox \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

    cp -rva assets/icon.png $icon
  '';

  nativeBuildInputs = [ pkgs.wrapGAppsHook pkgs.makeWrapper pkgs.patchelf ];
  dontWrapGApps = true;

  meta = libparsec.meta // {
    mainProgram = binName;
    description = "Open source Dropbox-like file sharing with full client encryption !";
  };
}
