{ pkgs, version, src, ... }:

pkgs.stdenv.mkDerivation {
  inherit version src;
  name = "parsec-cloud-src";
  outputs = [ "out" "doc" "icons" ];
  patches = [
    ./0001-Rework-poetry-dependencies-and-group.patch
    ./0002-Use-local-history-file-in-docs.patch
    ./0003-Fix-mountpoint_base_dir-not-a-Path.patch
    ./0004-Normalize-the-config-loading.patch
  ];
  configurePhase = ''
    mkdir -p icons

    cp parsec/core/gui/rc/images/icons/parsec.png icons/parsec.png
    cp packaging/windows/icon.ico icons/parsec.ico

    rm -rf windows-icon-handler packaging newsfragment json_schema .github .cspell
  '';
  dontBuild = true;
  patchFlags = "--strip=1 --verbose";
  installPhase = ''
    mkdir -p "$doc" "$out"
    cp -r docs/* HISTORY.rst "$doc"
    cp -r \
      oxidation src \
      Cargo.* rust-toolchain.toml \
      misc \
      parsec \
      pyproject.toml poetry.lock build.py make.py \
      README.rst HISTORY.rst \
      "$out"
    cp -r icons "$icons"
  '';
  dontFixup = true;
  meta = with pkgs.lib; {
    homepage = "https://parsec.cloud/";
    description = "Open source Dropbox-like file sharing with full client encryption !";
    branch = "releases/${majorMinor parsec-cloud-version}";
    license = with licenses; [ agpl3Only bsl11 ];
    changelog = "https://github.com/Scille/parsec-cloud/tree/v${parsec-cloud-version}/HISTORY.rst";
    platforms = platforms.all;
  };
}
