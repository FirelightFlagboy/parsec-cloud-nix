{
  autoPatchelfHook,
  dbus,
  fuse3,
  libgcc,
  openssl,
  pkg-config,
  source,
  sqlite,
  zstd,
}:

{
  cargoLock = {
    lockFile = "${source}/Cargo.lock";
    outputHashes = {
      "fuser-0.18.1" = "sha256-Aei/daoV3th+uAsoICkToXORcWZBZoX3st8wE2rtyig=";
      "scwsapi-0.8.1" = "sha256-0bblcz81lM5booIH2I17SHJEWIY2K/Pgk1hUOgpebVA=";
    };
  };

  nativeBuildInputs = [
    autoPatchelfHook
    pkg-config
  ];

  buildInputs = [
    dbus
    fuse3.dev
    libgcc
    openssl
    sqlite
    zstd.dev
  ];
}
