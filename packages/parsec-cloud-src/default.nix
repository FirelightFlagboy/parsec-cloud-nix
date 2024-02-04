{ pkgs, parsec-cloud-version, parsec-cloud-raw-src, ... }:

pkgs.stdenv.mkDerivation {
  name = "parsec-cloud-src";
  version = parsec-cloud-version;
  src = parsec-cloud-raw-src;
  outputs = [ "out" "doc" ];
  patches = [ ./parsec-cloud-poetry-deps.patch ./docs-use-local-HISTORY.patch ];
  configurePhase = ''
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
