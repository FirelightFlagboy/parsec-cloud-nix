{
  src,
  native-client-build,
  libparsec-node,
  electron_39,
  buildNpmPackage,
  wrapGAppsHook3,
  makeWrapper,
  patchelf,
  capacitor-electron,
  nix-update-script,
}:

let
  pkgVersion = libparsec-node.version;
  binName = "parsec";
  electron = electron_39;
in
buildNpmPackage {
  pname = "parsec-cloud";
  version = pkgVersion;
  outputs = [
    "out"
    "icon"
  ];

  src = "${src}/client/electron";

  npmDepsHash = "sha256-kokN1ZshtO/f/JP0ncHKjdCMOn/z07QthO5arOKuP+M=";
  makeCacheWritable = true;

  configurePhase = ''
    mkdir -pv build/{,generated-ts/}src app
    install -v -p -m 444 ${libparsec-node.typing}/libparsec.d.ts build/generated-ts/src/libparsec.d.ts
    install -v -p -m 555 ${libparsec-node}/libparsec.node build/src/libparsec.node
    cp -ra ${native-client-build}/. app
  '';

  # prevent electron download from electron in package.json
  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  };

  preBuild = ''
    # Patch '@capacitor-community/electron' not being build
    rm -rf node_modules/@capacitor-community/electron
    ln -s ${capacitor-electron}/lib/node_modules/@capacitor-community/electron node_modules/@capacitor-community/electron
  '';

  buildPhase = ''
    runHook preBuild

    npx tsc
    node package.js --mode prod --platform linux --export > electron-builder-config.json
    npm exec electron-builder -- \
      --linux \
      --dir \
      --config=electron-builder-config.json \
      --config.electronDist=${electron}/libexec/electron \
      --config.electronVersion=${electron.version}
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

  nativeBuildInputs = [
    wrapGAppsHook3
    makeWrapper
    patchelf
  ];
  dontWrapGApps = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--url=${src.src.url}"
      "--no-src" # No src to update, only npmDepsHash
    ];
  };

  meta = libparsec-node.meta // {
    mainProgram = binName;
    description = "Open source Dropbox-like file sharing with full client encryption !";
  };
}
