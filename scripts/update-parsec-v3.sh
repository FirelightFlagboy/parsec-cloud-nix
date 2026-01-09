set -eu -o pipefail

# Allow the user to overwrite `SCRIPTDIR` by exporting it beforehand.
SCRIPTDIR=${SCRIPTDIR:=$(dirname "$(realpath -s "$0")")}
# Allow the user to overwrite `ROOTDIR` by exporting it beforehand.
ROOTDIR=${ROOTDIR:=$(realpath -s "$SCRIPTDIR/..")}
UPDATE_MODE=${1:-stable}

nix run nixpkgs#nix-update -- --flake --version="$UPDATE_MODE" parsec-cloud.v3.src

function fail {
    local lc="$BASH_COMMAND" previous_rc=$?

    echo "An error occurred in the update script."
    echo "The following command exited with $previous_rc:"
    echo "$lc"
}

trap "fail" ERR

SOURCE=$(nix build .#parsec-cloud.v3.src --no-link --print-out-paths)

CLIENT_NPM_DEPS_HASH=$(nix run nixpkgs#prefetch-npm-deps "$SOURCE"/client/package-lock.json)
ELECTRON_NPM_DEPS_HASH=$(nix run nixpkgs#prefetch-npm-deps "$SOURCE"/client/electron/package-lock.json)

echo "Updating Npm dependencies hash"
sed -i \
    -e "s;npmDepsHash = \".*\";npmDepsHash = \"${CLIENT_NPM_DEPS_HASH}\";" \
    $ROOTDIR/packages/v3/native-build.nix

sed -i \
    -e "s;npmDepsHash = \".*\";npmDepsHash = \"${ELECTRON_NPM_DEPS_HASH}\";" \
    $ROOTDIR/packages/v3/electron-app.nix

if [ "$(git status --porcelain | grep -e packages/v3/source.nix -e packages/v3/native-build.nix -e packages/v3/electron-app.nix --count)" -ne 3 ]; then
    echo "Invalid number of file changes, a 'sed' command has failed"
    exit 1
fi
